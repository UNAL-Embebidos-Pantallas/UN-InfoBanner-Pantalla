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


static void save_test(unsigned int *addr)
{	
	volatile unsigned int *array = addr;
	unsigned int rgb = 0xD07; // First 12-bit value
	unsigned int rgb_aux;

	printf("RGB : %i\n",rgb);
	printf("Address : %i\n",addr);
	array[0] = rgb;
	rgb_aux = array[0];
	printf("RGB AUX : %i\n",rgb_aux);
}

static void save_data(unsigned int *addr)
{	
	volatile unsigned int *array = addr;
	unsigned int rgb; // First 12-bit value
	unsigned int dataRG = 0x0;
	unsigned int dataBR = 0x0;
	unsigned int dataGB = 0x0;
	int i;

	for(i =0; i<8; i++){
		rgb = (dataRG << 8) | (dataBR << 4) | dataGB;
		printf("RGB : %i\n",rgb);
		printf("Address : %i\n",addr);
		printf("i : %i\n",i);
		array[i] = rgb;
		dataBR++;
		dataGB++;
		dataRG++;
	}
}

static void save_colors(unsigned int *addr)
{	
	volatile unsigned int *array = addr;
	unsigned int rgb; // First 12-bit value
	unsigned int dataA = 0x0;
	unsigned int dataB = 0x0;
	int i;

	for(i = 0; i < 8; i++){
		rgb = (dataA << 6) | dataB; // Concatenación de dataA (6 bits) y dataB (6 bits)
		printf("RGB : %i\n", rgb);
		printf("Address : %i\n", addr);
		printf("i : %i\n", i);
		array[i] = rgb;
		dataA++;
		dataB++;
	}
}

static void from_mem(unsigned int *addr)
{
	volatile unsigned int *array = addr;
	int x, y; 
	int i=0;
	for(y=0; y<24; y++) {
		for(x=0; x<96; x++) {
			unsigned int value = array[i];
			rgb_cntrl_wr_en_write(0);
			rgb_cntrl_addr_a_write(y*96+x);
			rgb_cntrl_rgb_indat_a_write(value);
			rgb_cntrl_wr_en_write(1);
			addr++; // Move to the next address
			printf("Address : %i\n",addr);
			if ((x+1)%12==0){
				i++;
			}
		}
	}
}


static void matrix_rgb_test(unsigned int *addr)
{
	volatile unsigned int *array = addr;
	int x, y;
	for(y=0; y<24; y++) {
		for(x=0; x<96; x++) {
			rgb_cntrl_wr_en_write(0);
			rgb_cntrl_addr_a_write(y*96+x);
			if(x<96/3)	
				rgb_cntrl_rgb_indat_a_write((((int)(x/10)%2^(int)(y/10)%2)*15)<<2);
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
	unsigned int* addr = (unsigned int*)0x40000000;
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
	else if(strcmp(token, "from_mem") == 0)
		from_mem(addr);
	else if(strcmp(token, "save") == 0)
		save_test(addr);
	else if(strcmp(token, "save_data") == 0)
		save_data(addr);
	else if(strcmp(token, "save_colors") == 0)
		save_data(addr);
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
