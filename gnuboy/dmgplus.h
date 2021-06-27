#include "defs.h"
#include "sys.h"
#ifndef __DMGPLUS_H__
#define __DMGPLUS_H__

int dmgplus_cart_read(int addr, byte *data, int len);
int dmgplus_cart_write(int addr, byte *data, int len);
int dmgplus_init();

#endif