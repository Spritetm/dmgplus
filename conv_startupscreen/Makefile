OBJS=main.o
CFLAGS=-ggdb
LDFLAGS=-L/usr/local/lib/ -lgd
TARGET=mkssbin
$(TARGET): $(OBJS)
	$(CC) -o $@ $(LDFLAGS) $(OBJS)

clean:
	rm -f $(TARGET) $(OBJS)