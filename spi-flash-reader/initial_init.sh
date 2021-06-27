#!/bin/bash

#This script runs instead of init, so it boots in a more-or-less entirely unbooted
#system. The kernel is up, the root device is mounted... but that's it.

#We need these for spi, sound and input
modprobe matrix_keypad
modprobe spidev
modprobe spi-bcm2835
modprobe spi-bcm2835aux
modprobe snd_bcm2835

#rpi-gpio needs this
mount none /proc -t proc
mount none /sys -t sysfs

#Create dev node for spi
if [ ! -e /dev/spidev1.0 ]; then
	/bin/mknod /dev/spidev1.0 c 153 0
fi

#Configure GPIOs for SPI
/usr/bin/raspi-gpio set 18 op
/usr/bin/raspi-gpio set 19 a4
/usr/bin/raspi-gpio set 20 a4
/usr/bin/raspi-gpio set 21 a4

#cat /dev/tty1 > /dev/null &

/home/jeroen/spi_cart_reader/spi_cart_reader -check
res=$?

#/bin/bash

if [ $res = 0 ]; then
	#GameBoy cart. Run emu
	mount / -o remount,rw
	HOME=/root /home/jeroen/gnuboy/sdlgnuboy --bind w "+b" --bind x "+a" --bind enter "+start" --bind space "+select" /dev/null
	exec /sbin/init
elif [ $res = 2 ]; then
	name=`/home/jeroen/spi_cart_reader/spi_cart_reader -getname`
	if [ $name = doom ]; then
		HOME=/root /usr/games/doom -config /root/prboom.cfg
	elif [ $name = smw ]; then
		cd /root
		HOME=/root /home/jeroen/pisnes/snes9x "/home/jeroen/Super Mario World (USA).sfc"
	elif [ $name = sonic ]; then
		HOME=/root /home/jeroen/osmose-rpi/osmose "/home/jeroen/Sonic The Hedgehog (USA, Europe).sms" -nn2x -inifile /home/jeroen/osmose-rpi/osmose.ini
	fi
	exec /sbin/init
else
	exec /sbin/init
fi
