#CFLAGS += -ggdb -O0
#LDFLAGS += -ggdb
CFLAGS += -O2
LDFLAGS += -O2
LDLIBS += -lstrophe

.PHONY: all clean

all: xmppsend

clean:
	$(RM) xmppsend
