CFLAGS += -ggdb -O0
LDFLAGS += -ggdb
LDFLAGS += -lstrophe

.PHONY: all clean

all: xmppsend

clean:
	$(RM) xmppsend
