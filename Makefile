# Debugging Flags #
#CFLAGS += -ggdb -O0
#LDFLAGS += -ggdb

CFLAGS += -O2
LDFLAGS += -O2

# Homebrew installations of libstrophe #
# Uncomment the following two lines for certain
# OSX brew installations of libstrophe.
#CFLAGS += -I/usr/local/include
#LDFLAGS += -L/usr/local/lib

LDLIBS += -lstrophe

.PHONY: all clean

all: xmppsend xmpprecv

clean:
	$(RM) xmppsend
	$(RM) xmpprecv
