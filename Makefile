CFLAGS += -ggdb -O0
LDFLAGS += -ggdb
LDFLAGS += -lstrophe

.PHONY: all clean

all: xmppsend

xmppsend: xmppsend.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	$(RM) xmppsend
