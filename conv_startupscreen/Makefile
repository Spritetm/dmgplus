OBJS=main.o
CFLAGS=-ggdb
LDFLAGS=-L/usr/local/lib/ -lgd
TARGET=mkssbin
$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS)

clean:
	rm -f $(TARGET) $(OBJS)