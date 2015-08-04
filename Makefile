CFLAGS += -ggdb -O0
LDFLAGS += -ggdb
LDLIBS += -lstrophe

.PHONY: all clean

all: xmppsend

clean:
	$(RM) xmppsend
