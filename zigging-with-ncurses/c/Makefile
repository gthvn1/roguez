.PHONY: all clean

CC=gcc
SRC=hello.c
TARGET=hello
INC_DIR=$(HOME)/opt/ncurses/include
LIB_DIR=$(HOME)/opt/ncurses/lib64
CFLAGS=-I$(INC_DIR)
LFLAGS=-L$(LIB_DIR) -lncurses

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) -o $(TARGET) $(SRC) $(CFLAGS) $(LFLAGS)

clean:
	rm -f $(TARGET)
