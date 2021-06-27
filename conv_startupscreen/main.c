/*
Tool to create a 'fake' DMGPlus image
*/
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <gd.h>

const uint8_t ninty_logo[0x30]={
	0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 
	0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 
	0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 
	0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 
	0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E
};


typedef struct __attribute__((packed)) {
	char name[0x100-2]; //name of game, zero-terminated, used by RPi software to start correct program
	uint16_t delay;
	uint8_t sig[4]; //normally entry point, here 'DMG+'
	uint8_t logo[0x30];
	uint8_t startupscreen[5760]; //packed
} dmgplus_header_t;

//Main function
int main(int argc, char **argv) {
	if (argc<4) {
		printf("%s name-of-game startupscreen.png delay outputfile.bin\n", argv[0]);
		printf("delay is in (1/60th second) frames\n");
		exit(1);
	}

	dmgplus_header_t hdr={0};
	strcpy(hdr.name, argv[1]);
	hdr.delay=atoi(argv[3]);
	memcpy(hdr.sig, "DMG+", 4);
	memcpy(hdr.logo, ninty_logo, 0x30);

	gdImagePtr img;
	FILE *f=fopen(argv[2],"rb");
	if (f==NULL) {
		perror(argv[2]);
		return 1;
	}
	img=gdImageCreateFromPng(f);
	fclose(f);
	if (img==NULL) {
		printf("Couldn't load image: %s\n", argv[2]);
		return 1;
	}
	int i=0;
	for (int y=0; y<144; y++) {
		for (int x=0; x<160; x+=4) {
			int col=0;
			for (int n=0; n<4; n++) {
				int p=gdImageGetPixel(img, x+n, y);
				col<<=2;
				col+=(gdImageGreen(img, p)>>6);
			}
			hdr.startupscreen[i++]=col;
		}
	}
	
	f=fopen(argv[4], "wb");
	if (f==NULL) {
		perror(argv[4]);
		return 1;
	}
	fwrite(&hdr, sizeof(hdr), 1, f);
	fclose(f);
	return 0;
}
