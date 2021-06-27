#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include <string.h>
#include "hexdump.h"

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static void die(const char *s) {
	perror(s);
	exit(1);
}


typedef struct __attribute__((packed)) {
	uint8_t entry_point[4];
	uint8_t logo[0x30];
	uint8_t title[15];
	uint8_t cgb_flag;
	uint16_t licensee_new;
	uint8_t sgb_flag;
	uint8_t type;
	uint8_t rom_size;
	uint8_t ram_size;
	uint8_t dest_code;
	uint8_t licensee_old;
	uint8_t maskrom_ver;
	uint8_t hdr_chsum;
	uint16_t rom_checksum;
} gb_header_t;

typedef struct {
	int no;
	const char *desc;
	int sz;
} no_desc_t;

const no_desc_t cart_type_desc[]={
	{0x00, "ROM ONLY"},
	{0x01, "MBC1"},
	{0x02, "MBC1+RAM"},
	{0x03, "MBC1+RAM+BATTERY"},
	{0x05, "MBC2"},
	{0x06, "MBC2+BATTERY"},
	{0x08, "ROM+RAM"},
	{0x09, "ROM+RAM+BATTERY"},
	{0x0B, "MMM01"},
	{0x0C, "MMM01+RAM"},
	{0x0D, "MMM01+RAM+BATTERY"},
	{0x0F, "MBC3+TIMER+BATTERY"},
	{0x10, "MBC3+TIMER+RAM+BATTERY"},
	{0x11, "MBC3"},
	{0x12, "MBC3+RAM"},
	{0x13, "MBC3+RAM+BATTERY"},
	{0x19, "MBC5"},
	{0x1A, "MBC5+RAM"},
	{0x1B, "MBC5+RAM+BATTERY"},
	{0x1C, "MBC5+RUMBLE"},
	{0x1D, "MBC5+RUMBLE+RAM"},
	{0x1E, "MBC5+RUMBLE+RAM+BATTERY"},
	{0x20, "MBC6"},
	{0x22, "MBC7+SENSOR+RUMBLE+RAM+BATTERY"},
	{0xFC, "POCKET CAMERA"},
	{0xFD, "BANDAI TAMA5"},
	{0xFE, "HuC3"},
	{0xFF, "HuC1+RAM+BATTERY"},
	{0, NULL}
};

const no_desc_t rom_size_desc[]={
	{0x00, "32KByte (2 banks, no mbc)"},
	{0x01, "64KByte (4 banks)"},
	{0x02, "128KByte (8 banks)"},
	{0x03, "256KByte (16 banks)"},
	{0x04, "512KByte (32 banks)"},
	{0x05, "1MByte (64 banks)  - only 63 banks used by MBC1"},
	{0x06, "2MByte (128 banks) - only 125 banks used by MBC1"},
	{0x07, "4MByte (256 banks)"},
	{0x08, "8MByte (512 banks)"},
	{0x52, "1.1MByte (72 banks)"},
	{0x53, "1.2MByte (80 banks)"},
	{0x54, "1.5MByte (96 banks)"},
	{0, NULL}
};

const no_desc_t ram_size_desc[]={
	{0x01, "2 KBytes"},
	{0x02, "8 Kbytes"},
	{0x03, "32 KBytes (4 banks of 8KBytes each)"},
	{0x04, "128 KBytes (16 banks of 8KBytes each)"},
	{0, NULL}
};

const no_desc_t lang_desc[]={
	{0x05, "64 KBytes (8 banks of 8KBytes each)00h - Japanese"},
	{0x01, "Non-Japanese"},
	{0, NULL}
};

const uint8_t ninty_logo[0x30]={
	0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 
	0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 
	0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 
	0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 
	0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E
};

int get_rom_bank_count(gb_header_t *hdr) {
	int v=hdr->rom_size;
	if (v<=8) {
		return 2*(1<<v);
	}
	if (v==0x52) return 72;
	if (v==0x53) return 80;
	if (v==0x54) return 96;
	return 2; //assume 32K rom
}

const char *select_desc(int no, const no_desc_t *desc) {
	static const char *ret="(unknown)";
	int i=0;
	while (desc[i].desc!=NULL) {
		if (desc[i].no==no) ret=desc[i].desc;
		i++;
	}
	return ret;
}

void show_gb_hdr_info(gb_header_t *hdr) {
	char title[17]={0};
	for (int i=0; i<16; i++) {
		if (hdr->title[i]==0 || hdr->title[i]>96) break;
		title[i]=hdr->title[i];
	}
	printf("Cart title: %s\n", title);
	printf("Cart type: %s\n", select_desc(hdr->type, cart_type_desc));
	printf("Cart size: %s\n", select_desc(hdr->rom_size, rom_size_desc));
	printf("Cart ram size: %s\n", select_desc(hdr->ram_size, ram_size_desc));
}


void gbcart_read(int fd, uint32_t addr, uint32_t len, uint8_t *buff) {
	uint8_t tx[3]={0};
	tx[0]=(addr>>8)&0x7f;
	tx[1]=addr&0xff;
	struct spi_ioc_transfer tr[3]={
		{
			.tx_buf = (unsigned long)tx,
			.len = 3,
			.cs_change=0
		},{
			.rx_buf=(unsigned long)buff,
			.len=len,
//			.delay_usecs=100,
			.cs_change=1
		},{
			.delay_usecs=5,
			.cs_change=1
		}
	};

	int ret = ioctl(fd, SPI_IOC_MESSAGE(3), tr);
	if (ret < 1) die("can't send spi message");
}

uint8_t gbcart_read_byte(int fd, uint32_t addr) {
	uint8_t ret;
	gbcart_read(fd, addr, 1, &ret);
	return ret;
}

void gbcart_write(int fd, uint32_t addr, uint32_t len, uint8_t *buff) {
	uint8_t tx[2]={0};
	tx[0]=(addr>>8)|0x80;
	tx[1]=addr&0xff;
	struct spi_ioc_transfer tr[3]={
		{
			.tx_buf = (unsigned long)tx,
			.len = 2,
			.cs_change=0
		},{
			.tx_buf=(unsigned long)buff,
			.len=len,
			.cs_change=1
		},{
			.delay_usecs=2,
			.cs_change=1
		}
	};

	int ret = ioctl(fd, SPI_IOC_MESSAGE(3), tr);
	if (ret < 1) die("can't send spi message");
}

void gbcart_write_byte(int fd, uint32_t addr, uint8_t byte) {
	gbcart_write(fd, addr, 1, &byte);
}

uint8_t mangle_flashchip_data(uint8_t byte) {
	uint8_t frobbyte=byte&0xFC;
	if (byte&1) frobbyte|=2;
	if (byte&2) frobbyte|=1;
	return frobbyte;
}

void poke_flashchip(int fd, int addr, int byte) {
	gbcart_write_byte(fd, addr, mangle_flashchip_data(byte));
}

int validate_cfi_data(uint8_t *buf) {
	if (buf[0x20]!='Q' || buf[0x22]!='R' || buf[0x24]!='Y') {
		printf("CFI data invalid. No flash cart?\n");
		return 0;
	}
	int n=buf[0x4E];
	printf("Found flash device: %d Kib\n", (1<<(n-10)));
}

void flash_wait_toggle(int fd, int addr) {
	uint8_t b1[2], b2[2];
	do {
		gbcart_read(fd, addr, 2, b1);
		gbcart_read(fd, addr, 1, b2);
//		printf("%02X %02X\n", b1[0], b2[0]);
	} while (b1[0]!=b2[0]);
}


int main(int argc, char *argv[]) {
	int ret = 0;

#if 0
	system("raspi-gpio set 18 op");
	system("raspi-gpio set 19 a4");
	system("raspi-gpio set 20 a4");
	system("raspi-gpio set 21 a4");
#endif
	
	char *dumpfile=NULL;
	int check=0;
	int dowrite=0;
	int doerase=0;
	int getname=0;
	for (int i=1; i<argc; i++) {
		if (strcmp(argv[i], "-check")==0) {
			check=1;
		} else if (strcmp(argv[i], "-getname")==0) {
			getname=1;
		} else if (strcmp(argv[i], "-write")==0) {
			dowrite=1;
		} else if (strcmp(argv[i], "-erase")==0) {
			doerase=1;
		} else if (dumpfile==NULL) {
			dumpfile=argv[i];
		} else {
			printf("Error: did not understand %s\n", argv[i]);
			printf("Usage: %s [-check] [-getname] [-write [-erase]] [dumpfile.bin]\n", argv[0]);
			exit(1);
		}
	}

	const char *device="/dev/spidev1.0";
	int mode=SPI_MODE_0|SPI_CS_HIGH;
	int speed=8000000;
	int delay_us=0;
	int bits=8;

	int fd = open(device, O_RDWR);
	if (fd < 0) die("can't open device");
	ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
	if (ret == -1) die("can't set spi mode");
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1) die("can't set bits per word");
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1) die("can't set max speed hz");

	gb_header_t hdr={0};
	gbcart_read(fd, 0x100, sizeof(hdr), (uint8_t*)&hdr);
	
	if (check || getname) {
		int hdr_ok=1;
		int logo_ok=1;
		int is_dmgplus=0;
		if (check) show_gb_hdr_info(&hdr);
		if (memcmp(hdr.logo, ninty_logo, 0x30)!=0) {
			hdr_ok=0;
			logo_ok=0;
			if (check) printf("Header check failed: Nintendo logo data corrupted.\n");
		}
		uint8_t chs=0;
		uint8_t *chsmem=(uint8_t*)&hdr.title;
		for (int i=0; i<0x19; i++) chs=chs-chsmem[i]-1;
		if (chs!=hdr.hdr_chsum) {
			hdr_ok=0;
			if (check) printf("Header check failed: Checksum error (calc %02X read %02X).\n", chs, hdr.hdr_chsum);
		}
		if (logo_ok) {
			if (memcmp(hdr.entry_point, "DMG+", 4)==0) {
				if (check) printf("Cart is DMGPlus dummy cart\n");
				is_dmgplus=1;
			}
		}
		if (getname) {
			if (hdr_ok) {
				printf("%s\n", hdr.title);
			} else if (is_dmgplus) {
				char buff[128];
				gbcart_read(fd, 0x0, 128, (uint8_t*)buff);
				printf("%s\n", buff);
			} else {
				printf("-\n");
			}
		}

		if (hdr_ok) return 0;
		if (is_dmgplus) return 2;
		return 1;
	}

	if (dumpfile && !dowrite) {
		show_gb_hdr_info(&hdr);
		FILE *out=fopen(dumpfile, "wb");
		if (out==NULL) die(dumpfile);
		uint8_t rdata[256];
		int bankcnt=get_rom_bank_count(&hdr);

		for (int bankno=0; bankno<bankcnt; bankno++) {
			int addr;
			if (bankno==0) {
				addr=0;
			} else {
				addr=0x4000;
				uint8_t w[1]={bankno};
				gbcart_write(fd, 0x2000, 1, w);
			}
			int chs=0;
			printf("Reading bank %d of %d at 0x%x...\n", bankno, bankcnt, addr);
			for (int j=0; j<16*1024; j+=sizeof(rdata)) {
				gbcart_read(fd, addr+j, sizeof(rdata), rdata);
				fwrite(rdata, sizeof(rdata), 1, out);
				for (int i=0; i<sizeof(rdata); i++) chs+=rdata[i];
			}
			chs=(chs&0xffff)+(chs>>16);
			chs=(chs&0xffff)+(chs>>16);
			printf("Checksum: %x\n", chs);
		}
		fclose(out);
	}

	if (dumpfile && dowrite) {
		//Idea: Write bank to 0x2000 (0-n). Bank shows up at 4000-7FFF. Use that to poke the flash
		//chip. (That also messes with the RAM enable and mapping; soit.)
		printf("Checking flash cart...\n");
		gbcart_write_byte(fd, 0x2000, 0); //switch to bank 0
		poke_flashchip(fd, 0x00, 0xF0); //reset
		poke_flashchip(fd, 0x00, 0xF0); //reset

		poke_flashchip(fd, 0xAA, 0x98); //CFI query
		uint8_t buf[100];
		gbcart_read(fd, 0, 0x100, buf);
		poke_flashchip(fd, 0, 0); //exit CFI query
		for (int i=0; i<100; i++) buf[i]=mangle_flashchip_data(buf[i]);
		int r=validate_cfi_data(buf);
		if (!r) return 1;
		
		FILE *rom=fopen(dumpfile, "rb");
		if (rom==NULL) die(dumpfile);
		
		if (doerase) {
			printf("Erasing chip...\n");
			poke_flashchip(fd, 0x0, 0x0a);
			gbcart_write_byte(fd, 0x2000, 0x0); //switch to bank
			poke_flashchip(fd, 0x2100, 0xf4);
			poke_flashchip(fd, 0x4000, 0xf0);

			poke_flashchip(fd, 0xaaa, 0xaa);
			poke_flashchip(fd, 0x555, 0x55);
			poke_flashchip(fd, 0xaaa, 0x80);
			poke_flashchip(fd, 0xaaa, 0xaa);
			poke_flashchip(fd, 0x555, 0x55);
			poke_flashchip(fd, 0xaaa, 0x10); //erase chip
//			poke_flashchip(fd, 0x0000, 0x30); //erase sector 0
			flash_wait_toggle(fd, 0);

			int is_erased=0;
			while (!is_erased) {
				uint8_t data[1024];
				is_erased=1;
				gbcart_read(fd, 0x4000, 1024, data);
				printf("%x %x %x %x\n", data[0], data[1], data[0], data[1]);
				for (int i=0; i<1024; i++) {
					if (data[i]!=0xff) {
						is_erased=0;
						break;
					}
				}
			}
			printf("Erased.\n");
		}
		printf("Writing...\n");
		int bank=0;
		uint8_t rombank[16*1024];
		while (fread(rombank, 1, 16*1024, rom)>0) {
			printf("Bank %d\n", bank);
#if 0
			gbcart_write_byte(fd, 0x2000, bank); //switch to bank
			poke_flashchip(fd, 0x2100, 0xf4);
			for (int i=0; i<16*256; i+=4) {
				gbcart_write_byte(fd, 0x2000, bank); //switch to bank
				poke_flashchip(fd, 0x2100, 0xf4);
				//Send quad write command

				poke_flashchip(fd, 0x4000, 0xF0); //reset flash chip
				poke_flashchip(fd, 0xaaa, 0x56); //quad write
				gbcart_write(fd, i+0x4000, 4, &rombank[i]);
				uint8_t rb[4];
				for (int retry=2000; retry>0; retry--) {
					gbcart_read(fd, i+0x4000, 4, rb);
					if (memcmp(rb, &rombank[i], 4)==0) break;
				}

				if (memcmp(rb, &rombank[i], 4)!=0) {
					printf("Verification error at 0x%X!\n", i);
					printf("File:  %02X %02X %02X %02X\n", rombank[i], rombank[i+1], rombank[i+2], rombank[i+3]);
					printf("Flash: %02X %02X %02X %02X\n", rb[0], rb[1], rb[2], rb[3]);
					exit(0);
				}
			}
#else
			int retry_time=200;
			for (int i=0; i<16*1024; i++) {
				gbcart_write_byte(fd, 0x2000, bank); //switch to bank
				if (gbcart_read_byte(fd, i+0x4000)==rombank[i]) continue;

				//Send quad write command
				//note: flash only uses first 12 address bits for commands: FFF
				poke_flashchip(fd, 0x0, 0xF0);  //<-- without this, *some* writes go bad.
				poke_flashchip(fd, 0xaaa, 0xaa);
				poke_flashchip(fd, 0x555, 0x55);
				poke_flashchip(fd, 0xaaa, 0xa0);
				gbcart_write_byte(fd, i+0x4000, rombank[i]);

				uint8_t res[2];
				if (i==0xaaa || i==0xaab) usleep(10000); //don't ask
				for (int retry=0; retry<retry_time; retry++) {
					res[0]=gbcart_read_byte(fd, i+0x4000);
					res[1]=gbcart_read_byte(fd, i+0x4000);
					if (res[0]==res[1] && res[1]==rombank[i]) break;
				}
				if (res[0]!=rombank[i]) {
					printf("Error writing bank %d addr 0x%X! Data %x read %x/%x\n", bank, i, rombank[i], res[0], res[1]);
					retry_time*=2;
					if (retry_time<6400) {
						i--;
					} else {
						printf("Ignoring error.\n");
					}
				} else {
					retry_time=200;
				}
			}
#endif
			bank++;
		}
		printf("Done, %d banks written.\n", bank);
	}

	close(fd);
	return 0;
}
