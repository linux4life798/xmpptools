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

# echo "raw xml" | send
# xmpp_user=tom echo "raw xml" | send
send() {
	if (( DEBUG > 0 )); then
		font yellow >&2
		echo "Sending from: $xmpp_user@$xmpp_host" >&2
		font off >&2
	fi

	if (( DEBUG < 1 )); then
		sendxmpp --raw -u $xmpp_user -j $xmpp_host -p $xmpp_pass >&2
	elif (( DEBUG < 2)); then
		sendxmpp --raw -v -u $xmpp_user -j $xmpp_host -p $xmpp_pass >&2
	else
		sendxmpp --raw -d -u $xmpp_user -j $xmpp_host -p $xmpp_pass >&2
	fi
}

# This function allows you to input an unqualified jid, like bob
# and get the local qualified jid bob@example.com
# Example: jid=$(qualify_jid bob)
qualify_jid() {
	local to=$1
	if [[ "$to" =~ "@" ]]; then
		echo "${to}"
	else
		echo "${to}@${xmpp_host}"
	fi
}

# message <to> <message_body>
message() {
	local to=$(qualify_jid $1)

	# check args
	if (( $# < 2 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: message <to> <message_body>"
		return 0
	fi

	shift 1
	send <<-EOF
	<message to='$to' type='chat'>
		<body>$*</body>
	</message>
	EOF
}

# create <node>
create() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: create <node>"
		return 0
	fi

	send <<-EOF
	<iq type='set'
	to='pubsub.$xmpp_host'>
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
		<create node='$node'/>
		</pubsub>
	</iq>
	EOF
}

# publish <node> <item_id> <item_content>
publish() {
	local node=$1
	local id=$2
	shift 2

	# check args
	if (( $# < 3 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: publish <node> <item_id> <item_content>"
		return 0
	fi

	send <<-EOF
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
	local jid=$(qualify_jid $2)

	# check args
	if (( $# < 2 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: subscribe <node> <jid>"
		return 0
	fi

	send <<-EOF
	<iq type='set' to='pubsub.$xmpp_host'>
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
			<subscribe node='$node' jid='$jid'/>
		</pubsub>
	</iq>
	EOF
}
