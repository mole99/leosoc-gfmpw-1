#include <stdint.h>

static volatile long *const led_data = (volatile long *const) 0x0F000000;

typedef struct
{
	volatile uint32_t status;
	volatile uint32_t rx;
	volatile uint32_t tx;
	volatile uint32_t baudrate;
} uart_t;

static volatile uart_t *const uart0 = (volatile uart_t *const) 0x03000000;
static volatile uart_t *const uart1 = (volatile uart_t *const) 0x04000000;

#define RX_FLAG (1<<0) // high for received, clears on read
#define TX_FLAG (1<<1) // high on tx busy

typedef struct
{
	volatile uint32_t value;
	volatile uint32_t output_enable;
} gpio_t;

static volatile gpio_t *const gpio0 = (volatile gpio_t *const) 0x05000000;

typedef struct
{
	volatile uint32_t enable;
	volatile uint32_t output;
} trng_t;

static volatile trng_t *const trng0 = (volatile trng_t *const) 0x06000000;

void tx_uart(volatile uart_t* const uart, char data)
{
    while(uart->status & TX_FLAG);
    uart->tx = data;
}

char rx_uart(volatile uart_t* const uart)
{
    while(!(uart->status & RX_FLAG));
    return uart->rx;
}

int rx_uart_nonblocking(volatile uart_t* const uart, char* data)
{
    int flag = (uart->status & RX_FLAG) == RX_FLAG;
    *data = uart->rx;
    
    return flag;
}

void write(volatile uart_t* const uart, const char* message)
{
    while(*message != 0)
    {
        tx_uart(uart, *message);
        message++;
    }
}

void write_int(volatile uart_t* const uart, int num)
{
    if (num > 9)
    {
        int a = num / 10;
        num -= 10 * a;
        write_int(uart, a);
    }
    tx_uart(uart, '0' + num);
}

int get_instret(void)
{
    int instret;
    __asm__ volatile ("rdinstret %0" : "=r"(instret));
    return instret;
}

int get_cycle(void)
{
    int cycle;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

int get_mhartid(void)
{
    int mhartid;
    __asm volatile ( "csrr %0, mhartid" : "=r" ( mhartid ) );
    return mhartid;
}

int sync_flag = 0;

#define F_CPU 40000000
#define BAUDRATE_UART0 115200
#define BAUDRATE_UART1 9600

void main()
{
    *led_data = 1;
    *led_data = 0;
    *led_data = 1;
    
    int mhartid = get_mhartid();

    if (mhartid == 0) {
        gpio0->output_enable = 0xFFFF0000;
        gpio0->value = 0x12345678;
        uart0->baudrate = F_CPU / BAUDRATE_UART0;
        write_int(uart0, gpio0->value);
        tx_uart(uart0, '\n');
        write_int(uart0, trng0->output);
        tx_uart(uart0, '\n');
        //trng0->enable = 0xFFFFFFFF;
        write_int(uart0, trng0->output);
        tx_uart(uart0, '\n');
        write(uart0, "Core 0\n");
        //write(uart0, "Hello World on LeoRV32 :)\n");
        sync_flag = 1;
    }
    
    if (mhartid == 1) {
        //while (!sync_flag);
        uart1->baudrate = F_CPU / BAUDRATE_UART1;
        write(uart1, "Core 1\n");
        while (1);
    }

    while (1)
    {
        //tx_uart(uart0, rx_uart(uart0));
        
        while(!(uart0->status & RX_FLAG));
        int data = uart0->rx;
        
        while(uart0->status & TX_FLAG);
        uart0->tx = data;
    }
    
    while(1);
}
