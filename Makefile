TARGET := spi_cart_reader
OBJS := main.o
CFLAGS := -ggdb -Og
LDFLAGS :=

$(TARGET): $(OBJS)
	$(CC) -o $(TARGET) $(LDFLAGS) $(OBJS)

clean:
	rm -f $(TAGET) $(OBJS)

.PHONY: clean
