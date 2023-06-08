#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

#include "delay.h"

static char *readstr(void)
{
	char c[2];
	static char s[64];
	static int ptr = 0;

	if(readchar_nonblock()) {
		c[0] = readchar();
		c[1] = 0;
		switch(c[0]) {
			case 0x7f:
			case 0x08:
				if(ptr > 0) {
					ptr--;
					putsnonl("\x08 \x08");
				}
				break;
			case 0x07:
				break;
			case '\r':
			case '\n':
				s[ptr] = 0x00;
				putsnonl("\n");
				ptr = 0;
				return s;
			default:
				if(ptr >= (sizeof(s) - 1))
					break;
				putsnonl(c);
				s[ptr] = c[0];
				ptr++;
				break;
		}
	}
	return NULL;
}

static char *get_token(char **str)
{
	char *c, *d;

	c = (char *)strchr(*str, ' ');
	if(c == NULL) {
		d = *str;
		*str = *str+strlen(*str);
		return d;
	}
	*c = 0;
	d = *str;
	*str = c+1;
	return d;
}

static void prompt(void)
{
	printf("RUNTIME>");
}

static void help(void)
{
	puts("Available commands:");
	puts("help                            - this command");
	puts("reboot                          - reboot CPU");
	puts("display                         - display test");
	puts("matrix                          - matrix rgb test");
}

static void reboot(void)
{
	ctrl_reset_write(1);
}

static void display_test(void)
{
//	int i;
	printf("display_test...\n");
/*	for(i=0; i<6; i++) {
		display_sel_write(i);
		display_value_write(7);
		display_write_write(1);
	}
*/
}


/*
static void vga_test(void)
{
	int x,y;
	
	for(y=0; y<480; y++) {
		for(x=0; x<640; x++) {
			vga_cntrl_mem_we_write(0);
			vga_cntrl_mem_adr_write(y*640+x);
			if(x<640/3)	
				vga_cntrl_mem_data_w_write(((int)(x/10)%2^(int)(y/10)%2)*15);
			else if(x<2*640/3) 
				vga_cntrl_mem_data_w_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<4);
			else 
				vga_cntrl_mem_data_w_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<8);
			vga_cntrl_mem_we_write(1);
		}
	}
}
*/

static void matrix_rgb_test(unsigned int *addr)
{
	volatile unsigned int *array = addr;
	int x, y;
	for(y=0; y<24; y++) {
		for(x=0; x<96; x++) {
			rgb_cntrl_wr_en_write(0);
			rgb_cntrl_addr_a_write(y*96+x);
			if(x<96/3)	
				rgb_cntrl_rgb_indat_a_write(array[0]);
			else if(x<2*96/3) 
				rgb_cntrl_rgb_indat_a_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<4);
			else 
				rgb_cntrl_rgb_indat_a_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<8);
			rgb_cntrl_wr_en_write(1);
		}
	}
}

static void matrix_move(void)
{	
	int posx = 15;
	int posy = 0;
	int delta = 2;
	int x, y, addr;
	while (posy != 96) {
	for(y=0; y<24; y++) {
		for(x=0; x<96; x++) {
			rgb_cntrl_wr_en_write(0);
			addr = y*96+x;
			rgb_cntrl_addr_a_write(addr);
			if (addr == posx*96+posy || addr == (posx+delta)*96+(posy+delta))
				rgb_cntrl_rgb_indat_a_write(x*y);
			else
				rgb_cntrl_rgb_indat_a_write(0);
			rgb_cntrl_wr_en_write(1);
		}
	}
	posy++;
	delay_ms(100);
	}
}

static void console_service(void)
{
	char *str;
	char *token;
	int i=0;
	unsigned int addr = 0x40000000;
	str = readstr();
	if(str == NULL) return;
	token = get_token(&str);
	if(strcmp(token, "help") == 0)
		help();
	else if(strcmp(token, "reboot") == 0)
		reboot();
	// else if(strcmp(token, "led") == 0)
	// 	led_test();
	// else if(strcmp(token, "switch") == 0)
	// 	switch_test();
	else if(strcmp(token, "display") == 0)
		display_test();
	// else if(strcmp(token, "rgbled") == 0)
	// 	rgbled_test();
	// else if(strcmp(token, "infra") == 0)
	// 	GPIO_infra_test();
	else if(strcmp(token, "matrix") == 0)
		matrix_rgb_test(addr);
	else if(strcmp(token, "move") == 0)
		while(i!=10){
			matrix_move();
			i++;
		}
		i = 0;
	prompt();
}

int main(void)
{
	#ifdef CONFIG_CPU_HAS_INTERRUPT
	irq_setmask(0);
	irq_setie(1);
	#endif
	uart_init();

	puts("\nUN Banner SoC - VexRiscV project UNAL 2023-S1 "__DATE__" "__TIME__"\n");
	help();
	prompt();

	while(1) {
		console_service();
	}

	return 0;
}
