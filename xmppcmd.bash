#!/bin/bash
# Author: Craig Hesling <craig@hesling.com>
# Date: June 30, 2015
#
# Usage:
# . xmppcmd.sh [jid] [pass]
# The script can also get it's jid and password from the environemnt
#  variables XMPP_JID and XMPP_PASS or form the defaults specified below.
#
# Description:
# Upon sourcing, the startup script will try to assign user, host, and pass
# from the environment variables XMPP_JID and XMPP_PASS. If this fails, the
# set default values are used. Next, the startup script will try to override
# the user, host, and pass with argument supplied jid and pass. The previously
# set values are used if no arguments are supplied.

# Default Settings #
DEFAULT_DEBUG=1 # Values: 0 1 2
DEFAULT_XMPP_USER=bob          # Change This
DEFAULT_XMPP_HOST=example.com  # Change This
DEFAULT_XMPP_PASS=bobspassword # Change This


# Set DEBUG to default if environment doesn't set it
DEBUG=${DEBUG:-$DEFAULT_DEBUG}

# First try to set user, host, and pass from environemtn variable or default values #
JID=( ${XMPP_JID/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$DEFAULT_XMPP_USER}
xmpp_pass=${XMPP_PASS:-$DEFAULT_XMPP_PASS}
xmpp_host=${JID[1]:-$DEFAULT_XMPP_HOST}

# Now, set user, host, pass from arguments if avaliable #
JID=( ${1/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$xmpp_user}
xmpp_pass=${2:-$xmpp_pass}
xmpp_host=${JID[1]:-$xmpp_host}

# Source font library #
. font_simple.sh

# Print Configuration Settings #
if (( DEBUG > 0 )); then
	font bold
	echo "# General Settings #"
	font off
	echo "DEBUG=$DEBUG"
	font bold
	echo "# XMPP User Settings #"
	font off
	echo "user=$xmpp_user"
	echo "host=$xmpp_host"
	echo "pass=$xmpp_pass"
fi

# Check Utilities Needed #
if ! hash sendxmpp &>/dev/null; then
	font red bold >&2
	echo "Error - sendxmpp is not installed">&2
	font >&2
fi

SEND="sendxmpp --raw -u $xmpp_user -j $xmpp_host -p $xmpp_pass"

# message <to> <message_body>
message() {
	local to=$1
	shift 1
	$SEND <<-EOF
	<message to='$to' type='chat'>
		<body>$*</body>
	</message>
	EOF
}

# create <node>
create() {
	local node=$1
	$SEND <<-EOF
	<iq type='set'
	to='pubsub.$xmpp_host'>
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
		<create node='$node'/>
		</pubsub>
	</iq>
	EOF
}

# publish <node> <item_id>
publish() {
	local node=$1
	local id=$2
	shift 2
	$SEND <<-EOF
	<iq type='set' to='pubsub.$xmpp_host'>
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
			<publish node='$node'>
				<item id='$id'>
					$*
				</item>
			</publish>
		</pubsub>
	</iq>
	EOF
}

# subscribe <node> <jid>
subscribe() {
	local node=$1
	local jid=$2
	shift 2
	$SEND <<-EOF
	<iq type='set' to='pubsub.$xmpp_host'>
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
			<subscribe node='$node' jid='$jid'/>
		</pubsub>
	</iq>
	EOF
}
