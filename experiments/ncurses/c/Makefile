.PHONY: all clean

CC=gcc
SRC=hello.c
TARGET=hello
INC_DIR=../ncurses-build/include
LIB_DIR=../ncurses-build/lib
CFLAGS=-I$(INC_DIR)
LFLAGS=-L$(LIB_DIR) -lncursesw

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) -o $(TARGET) $(SRC) $(CFLAGS) $(LFLAGS)

clean:
	rm -f $(TARGET)
