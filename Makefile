#CFLAGS += -ggdb -O0
#LDFLAGS += -ggdb
CFLAGS += -O2
LDFLAGS += -O2
LDLIBS += -lstrophe

.PHONY: all clean

all: xmppsend xmpprecv

clean:
	$(RM) xmppsend
	$(RM) xmpprecv
