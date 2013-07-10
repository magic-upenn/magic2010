CC = gcc
CFLAGS = -g 

INCLUDES = -I./C/include -I$(MAGIC_DIR)/ipc
LIBS = -lrt -lipc
DRIVERS = ./C/*.c

SRC = runEStopCtrlGateway.c

all: clean $(SRC:.c=)

.c:
	$(CC) $(CFLAGS) $< $(DRIVERS) $(LIBS) -o $@ $(INCLUDES) $(LIBS)

clean:
	$(RM) $(SRC:.c=)
