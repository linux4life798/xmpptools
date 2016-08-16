#!/bin/bash
# Author: Craig Hesling <craig@hesling.com>
# Date: June 30, 2015
#
# Usage:
# . xmppcmd.sh [jid] [pass]
# The script can also get it's jid and password from the environment
#  variables XMPP_JID and XMPP_PASS or from the defaults specified below.
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

# First try to set user, host, and pass from environment variable or default values #
JID=( ${XMPP_JID/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$DEFAULT_XMPP_USER}
xmpp_pass=${XMPP_PASS:-$DEFAULT_XMPP_PASS}
xmpp_host=${JID[1]:-$DEFAULT_XMPP_HOST}

# Now, set user, host, pass from arguments if available #
JID=( ${1/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$xmpp_user}
xmpp_pass=${2:-$xmpp_pass}
xmpp_host=${JID[1]:-$xmpp_host}

# Runtime Settings #
XML_PRETTYPRINT_UTIL="xmllint"
XMPPTOOLS_DIR=`dirname $BASH_SOURCE`

# Source font library #
. $XMPPTOOLS_DIR/font_simple.sh

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

# Check for Utilities Needed #

if ! hash xmllint &>/dev/null; then
	font red bold >&2
	echo "Error - xmllint (Deb pkg libxml2-utils) is not installed">&2
	echo "      - XML pretty printing will be disabled">&2
	font off >&2
	XML_PRETTYPRINT_UTIL=cat
fi

if [ ! -e $XMPPTOOLS_DIR/xmppsend ]; then
	font red bold >&2
	echo "Error - xmppsend is not built">&2
	echo "      - run make">&2
	font off >&2
fi

# Using the commandline utility sendxmpp
# echo "raw xml" | send
# xmpp_user=tom echo "raw xml" | send
send_sendxmpp() {

	# Check if sendxmpp is installed
	if ! hash sendxmpp &>/dev/null; then
		font red bold >&2
		echo "Error - sendxmpp is not installed">&2
		font off >&2
		return
	fi

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

# Using the custom commandline program xmppsend for two-way comm
# send_xmpp [stanza_id]
send_xmppsend() {
	local stanza_id=$1

	if (( DEBUG > 0 )); then
		font yellow >&2
		echo "Sending from: $xmpp_user@$xmpp_host" >&2
		font off >&2
	fi

	if (( DEBUG < 1 )); then
		# Silent Mode - Throw away debug info
		$XMPPTOOLS_DIR/xmppsend "${xmpp_user}@${xmpp_host}" ${xmpp_pass} ${stanza_id} 2>/dev/null
	else
		# Show Debug Info - Display in blue
		font blue >&2
		$XMPPTOOLS_DIR/xmppsend "${xmpp_user}@${xmpp_host}" ${xmpp_pass} ${stanza_id}
		font off >&2
	fi
}

xml_prettyprint() {
	case $XML_PRETTYPRINT_UTIL in
		xmllint)
			# tail will kill the first line, which is an inserted xml version line
			# we also kill errors emitted by xmllint
			xmllint --format --recover --nowarning - | tail -n +2
			;;
		*)
			$XML_PRETTYPRINT_UTIL
			;;
	esac
}

# echo "raw xml" | send
# xmpp_user=tom echo "raw xml" | send
send() {
	#send_sendxmpp $@
	if [ $# -gt 0 ]; then
		send_xmppsend $@ | xml_prettyprint
	else
		send_xmppsend
	fi
}

# This function allows you to input an unqualified jid, like bob
# and get the local qualified jid bob@example.com
# Example: jid=$(qualify_jid bob)
qualify_jid() {
	local to=$1
	if [[ "$to" =~ "@" ]]; then
		# already qualified - pass through
		echo "${to}"
	elif [[ "$to" =~ "pubsub" ]]; then
		# special pubsub - pass through
		echo "${to}"
	elif [ "$to" == "" ]; then
		# special blank - pass through
		echo "$to"
	else
		# unqualified jid - automatically qualify
		echo "${to}@${xmpp_host}"
	fi
}

# stanza_iq <type> [to]
# Special functionality: if [to] is "", the to attribute is omitted
# Example: echo "<atom>blah</atom>" | send_stanza_iq get
send_stanza_iq() {
	local typ=$1
	local to=$(qualify_jid ${2-pubsub.$xmpp_host})

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: stanza_iq <type> [to]"
		return 0
	fi

	local id=`newid`
	{
		# Head
		if [ "$to" != "" ]; then
			cat <<-EOF
			<iq type='$typ'
				id='$id'
				to='$to'>
			EOF
		else
			cat <<-EOF
			<iq type='$typ'
				id='$id'>
			EOF
		fi

		# Body
		cat

		# Tail
		cat <<-EOF
		</iq>
		EOF
	} | send $id
}

# stanza_pubsub [owner]
stanza_pubsub() {

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: stanza_pubsub [owner]"
		return 0
	fi

	local ns="http://jabber.org/protocol/pubsub"

	if [ $# -gt 0 ]; then
		ns+="#owner"
	fi

	# Head
	cat <<-EOF
	<pubsub xmlns='$ns'>
	EOF

	# Body
	cat

	# Tail
	cat <<-EOF
	</pubsub>
	EOF
}

# Generate a unique id
newid() {
	echo "xmppsend$RANDOM"
}

# Show the help message
xmpphelp() {
	local XMPP_CMDS=( xmpphelp )
	XMPP_CMDS+=( get_jid get_pass )
	XMPP_CMDS+=( message create delete publish purge )
	XMPP_CMDS+=( subscribe unsubscribe )
	XMPP_CMDS+=( get_nodes get_items get_item )
	XMPP_CMDS+=( get_subscriptions get_subscribers set_subscribers )
	XMPP_CMDS+=( get_affiliations get_affiliates set_affiliations )
	XMPP_CMDS+=( get_vcard set_vcard )
	XMPP_CMDS+=( send send_stanza_iq stanza_pubsub )

	font bold
	echo "Valid commands:"
	font off
	for i in ${XMPP_CMDS[@]}; do
		echo "	$i"
	done
}

# Print out the active jid
get_jid() {
	echo ${xmpp_user}@${xmpp_host}
}

# Print out the active password
get_pass() {
	echo ${xmpp_pass}
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
	local id=`newid`
	send <<-EOF
	<message type='chat'
			 id='$id'
			 to='$to'>
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

	echo "<create node='$node'/>" \
		| stanza_pubsub \
		| send_stanza_iq set
}

# Delete a node
# delete <node>
delete() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: delete <node>"
		return 0
	fi

	echo "<delete node='$node'/>" \
		| stanza_pubsub owner \
		| send_stanza_iq set
}
#
# publish <node> <item_id> [ <item_content> | - ]
publish() {
	local node=$1
	local item_id=$2

	# check args
	if (( $# < 3 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: publish <node> <item_id> [ <item_content> | - ]"
		echo
		echo "       Using the \"-\" indicates using stdin as item_content"
		return 0
	fi

	shift 2
	local id=`newid`
	{
		# Emit the beginning of the publish message
		cat <<-EOF
		<iq type='set'
			id='$id'
			to='pubsub.$xmpp_host'>
			<pubsub xmlns='http://jabber.org/protocol/pubsub'>
				<publish node='$node'>
					<item id='$item_id'>
		EOF

		# Emit content to publish
		if [ "$*" = "-" ]; then
			cat | sed 's/^[ \t]*//;s/[ \t]*$//'
		else
			echo $*
		fi

		# Emit the ending of the publish message
		cat <<-EOF
					</item>
				</publish>
			</pubsub>
		</iq>
		EOF
	} \
		| send $id
}

# Purge all node items
# purge <node>
purge() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: purge <node>"
		return 0
	fi

	echo "<purge node='$node'/>" \
		| stanza_pubsub owner \
		| send_stanza_iq set
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

	echo "<subscribe node='$node' jid='$jid'/>" \
		| stanza_pubsub \
		| send_stanza_iq set
}

# unsubscribe <node> <jid>
unsubscribe() {
	local node=$1
	local jid=$(qualify_jid $2)

	# check args
	if (( $# < 2 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: unsubscribe <node> <jid>"
		return 0
	fi

	echo "<unsubscribe node='$node' jid='$jid'/>" \
		| stanza_pubsub \
		| send_stanza_iq set
}

# get_nodes
get_nodes() {
	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_nodes"
		return 0
	fi

	echo "<query xmlns='http://jabber.org/protocol/disco#items'/>" \
		| send_stanza_iq get
}

# get_subscriptions
get_subscriptions() {
	local node=$1

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_subscriptions"
		return 0
	fi

	echo "<subscriptions node='$node'/>" \
		| stanza_pubsub \
		| send_stanza_iq get
}

# Get a list of subscribers of a node
# get_subscribers <node>
get_subscribers() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Get a list of subscribers of a given node" >&2
		echo "Usage: get_subscribers <node>" >&2
		return 0
	fi

	echo "<subscriptions node='$node'/>" \
		| stanza_pubsub owner \
		| send_stanza_iq get
}

# Set subscribers for a given node
# Subscription states can be "none", "pending", "unconfigured", or "subscribed"
# See http://www.xmpp.org/extensions/xep-0060.html#substates
# set_subscribers <node> <jid> <subscription_state> [<jid2> <subscription_state2>] [...]
set_subscribers() {
	local node=$1

	# check args
	if (( $# < 3 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: set_subscribers <node> <jid> <affiliation> [<jid2> <affiliation2>] [...]" >&2
		return 0
	fi

	shift 1

	{
		echo "<subscriptions node='$node'>"

		while [ $# -gt 0 ]; do
			if [ $# -lt 2 ]; then
				echo "Error - Impropper number of arguments" >&2
				return 1
			fi

			local jid=$(qualify_jid $1)
			local subscription=$2
			shift 2

			echo "<subscription jid='$jid' subscription='$subscription'/>"
		done

		echo "</subscriptions>"
	} \
		| stanza_pubsub owner \
		| send_stanza_iq set

}

# get_affiliations
get_affiliations() {
	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_affiliations"
		return 0
	fi

	echo "<affiliations/>" \
		| stanza_pubsub \
		| send_stanza_iq get

}

# get_affiliates <node>
get_affiliates() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_affiliates <node>"
		return 0
	fi

	echo "<affiliations node='$node'/>" \
		| stanza_pubsub owner \
		| send_stanza_iq get

}

# Set affiliations for a given node
# Affiliation can be "owner", "member", "publisher", "publish-only", "outcast", or "none"
# set_affiliations <node> <jid> <affiliation> [<jid2> <affiliation2>] [...]
set_affiliations() {
	local node=$1

	# check args
	if (( $# < 3 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: set_affiliations <node> <jid> <affiliation> [<jid2> <affiliation2>] [...]" >&2
		return 0
	fi

	shift 1

	{
		echo "<affiliations node='$node'>"

		while [ $# -gt 0 ]; do
			if [ $# -lt 2 ]; then
				echo "Error - Impropper number of arguments" >&2
				return 1
			fi

			local jid=$(qualify_jid $1)
			local affiliation=$2
			shift 2

			echo "<affiliation jid='$jid' affiliation='$affiliation'/>"
		done

		echo "</affiliations>"
	} \
		| stanza_pubsub owner \
		| send_stanza_iq set

}

# Get items for a node
# get_items <node>
get_items() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_items <node>"
		return 0
	fi

	echo "<query xmlns='http://jabber.org/protocol/disco#items' node='$node'/>" \
		| send_stanza_iq get
}

# Get item for a node
# get_item <node> <item_id> [item_id2 [item_id3...]]
get_item() {
	local node=$1

	# check args
	if (( $# < 2 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_item <node> <item_id> [item_id2 [item_id3...]]"
		return 0
	fi

	shift 1

	{
		echo "<items node='$node'>"

		while [ $# -gt 0 ]; do

			local item_id=$1
			shift 1

			echo "<item id='$item_id' />"
		done

		echo "</items>"
	} \
		| stanza_pubsub \
		| send_stanza_iq get

}

# Get vCard info for jid
# get_vcard <jid>
get_vcard() {
	local jid=$(qualify_jid $1)

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_vcard <jid>"
		return 0
	fi

	echo "<vCard xmlns='vcard-temp'/>" \
		| send_stanza_iq get $jid
}

# Set vCard info
# cat <vcard_file> | set_vcard
set_vcard() {

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: cat <vcard_file> | set_vcard"
		return 0
	fi

	# file should have <vCard xmlns='vcard-temp'></vCard> inside
	send_stanza_iq set ""
}
