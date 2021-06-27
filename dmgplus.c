#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include "dmgplus.h"
#include "defs.h"
#include "sys.h"

int dmgplus_fd=-1;

int dmgplus_init() {
	//hack: redirect gpio to spi
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
	int ret;
	if (fd < 0) die("can't open device");
	ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
	if (ret == -1) die("can't set spi mode");
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1) die("can't set bits per word");
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1) die("can't set max speed hz");
	
	dmgplus_fd=fd;
	return 1;
}

int dmgplus_cart_read(int addr, byte *data, int len) {
	uint8_t tx[3]={0};
	tx[0]=(addr>>8)&0x7f;
	tx[1]=addr&0xff;
	struct spi_ioc_transfer tr[3]={
		{
			.tx_buf = (unsigned long)tx,
			.len = 3,
			.cs_change=0
		},{
			.rx_buf=(unsigned long)data,
			.len=len,
//			.delay_usecs=100,
			.cs_change=1
		},{
			.delay_usecs=5,
			.cs_change=1
		}
	};

	int ret = ioctl(dmgplus_fd, SPI_IOC_MESSAGE(3), tr);
	return (ret>=1);
}

int dmgplus_cart_write(int addr, byte *data, int len) {
	uint8_t tx[2]={0};
	tx[0]=(addr>>8)|0x80;
	tx[1]=addr&0xff;
	struct spi_ioc_transfer tr[3]={
		{
			.tx_buf = (unsigned long)tx,
			.len = 2,
			.cs_change=0
		},{
			.tx_buf=(unsigned long)data,
			.len=len,
			.cs_change=1
		},{
			.delay_usecs=5,
			.cs_change=1
		}
	};

	int ret = ioctl(dmgplus_fd, SPI_IOC_MESSAGE(3), tr);
	return (ret>=1);
}

