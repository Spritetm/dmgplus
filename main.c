#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static void die(const char *s) {
	perror(s);
	exit(1);
}


typedef struct __attribute__((packed)) {
	uint32_t entry_point;
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

int get_rom_bank_count(gb_header_t *hdr) {
	int v=hdr->rom_size;
	if (v<=8) {
		return 2*(1<<v);
	}
	if (v==0x52) return 72;
	if (v==0x53) return 80;
	if (v==0x54) return 96;
	return 0;
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
			.delay_usecs=5,
			.cs_change=1
		}
	};

	int ret = ioctl(fd, SPI_IOC_MESSAGE(3), tr);
	if (ret < 1) die("can't send spi message");
}


int main(int argc, char *argv[]) {
	int ret = 0;

	system("raspi-gpio set 18 op");
	system("raspi-gpio set 19 a4");
	system("raspi-gpio set 20 a4");
	system("raspi-gpio set 21 a4");

	const char *device="/dev/spidev1.0";
	int mode=SPI_MODE_0|SPI_CS_HIGH;
	int speed=1000000;
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
	show_gb_hdr_info(&hdr);

	if (argc==1) return 0;

	FILE *out=fopen(argv[1], "wb");
	if (out==NULL) die(argv[1]);
	uint8_t rdata[256];
	int bankcnt=get_rom_bank_count(&hdr);
	for (int bankno=0; bankno<bankcnt; bankno++) {
		int addr;
		if (bankno==0) {
			addr=0;
		} else {
			addr=0x4000;
			uint8_t w=bankno;
			gbcart_write(fd, 0x2000, 1, &w);
		}
		printf("Reading bank %d of %d at 0x%x...\n", bankno, bankcnt, addr);
		for (int j=0; j<16*1024; j+=sizeof(rdata)) {
			gbcart_read(fd, addr+j, sizeof(rdata), rdata);
			fwrite(rdata, sizeof(rdata), 1, out);
		}
	}
	fclose(out);

	close(fd);
	return 0;
}
