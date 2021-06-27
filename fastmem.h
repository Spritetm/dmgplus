
#ifndef __FASTMEM_H__
#define __FASTMEM_H__


#include "defs.h"
#include "mem.h"
#include <stdio.h>

static byte readb(int a)
{
	byte *p = mbc.rmap[a>>12];
	if (p) return p[a];
	else return mem_read(a);
}

static void writeb(int a, byte b)
{
	byte *p = mbc.wmap[a>>12];
	if (p) p[a] = b;
	else mem_write(a, b);
}

static int readw(int a)
{
	return readb(a) | (readb(a+1)<<8);
}

static void writew(int a, int w)
{
	writeb(a, w);
	writeb(a+1, w>>8);
}

static byte readhi(int a)
{
	return readb(a | 0xff00);
}

static void writehi(int a, byte b)
{
	writeb(a | 0xff00, b);
}

#if 0
static byte readhi(int a)
{
	byte (*rd)() = hi_read[a];
	return rd ? rd(a) : (ram.hi[a] | himask[a]);
}

static void writehi(int a, byte b)
{
	byte (*wr)() = hi_write[a];
	if (wr) wr(a, b);
	else ram.hi[a] = b & ~himask[a];
}
#endif


#endif
