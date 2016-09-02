#!/bin/bash
# Author: Craig Hesling <craig@hesling.com>
# Date: June 30, 2015
#       August 30, 2016
#
# Usage:
# . xmppcmd.sh [jid] [pass] [pubsub_host]
# The script can also get it's jid, password, and pubsub host from
#  the environment variables XMPP_JID, XMPP_PASS, and XMPP_PUBSUB
#  OR from the defaults specified in a xmpprc file.
#
# Description:
# Upon sourcing, the startup script will try to assign user, host, pass,
# and pubsub server from the environment variables XMPP_JID, XMPP_PASS, and
# XMPP_PUBSUB. If this fails, the default values from a local or
# ~/.config/xmpprc file are used. Next, the startup script will try to
# override the user, host, pass, and pubsub host with argument supplied jid,
# pass, and pubsub host. The previously set values are used if no arguments
# are supplied.
# Settings:
# Command line args override environmental vars, environmental vars override
# an xmpprc in the working directory, and an xmpprc in the working directory
# overrides the ~/.config/xmpprc
XMPPCMD_VERSION=2.0

# Master list of user commands
XMPP_CMDS=( )
XMPP_CMDS+=( xmpphelp , )
XMPP_CMDS+=( pretty , )
XMPP_CMDS+=( get_config get_jid get_pass get_pubsub , )
XMPP_CMDS+=( message create delete publish purge , )
XMPP_CMDS+=( subscribe unsubscribe , )
XMPP_CMDS+=( get_nodes get_items get_item , )
XMPP_CMDS+=( get_subscriptions get_subscribers set_subscribers , )
XMPP_CMDS+=( get_affiliations get_affiliates set_affiliations , )
XMPP_CMDS+=( get_vcard set_vcard , )
XMPP_CMDS+=( send send_stanza_iq stanza_pubsub )

# DEPRECIATED method
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

fatten_and_check() {
	xmllint --dropdtd --nowrap --noblanks - | tail -n +2
}

# Format and print xml given on stdin if enabled
# echo "raw xml" | xml_prettyprint
xml_prettyprint() {

	# bypass pretty print util when disabled
	if (( ! xml_pretty_enable )); then
		cat
		return 0
	fi

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

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: send"
		return 0
	fi

	#send_sendxmpp $@
	if [ $# -gt 0 ]; then
		fatten_and_check | send_xmppsend $@ | xml_prettyprint
	else
		flatten_and_check | send_xmppsend
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
	local to=$(qualify_jid ${2-$xmpp_pubsub})

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
alias xhelp='xmpphelp'
xmpphelp() {

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: xmpphelp [command1 [command2 [...]]]"
		echo "Get help with one or many commands"
		return 0
	fi

	if [ $# -gt 0 ]; then
		# Get help for certain commands
		for i; do
			echo "$ $i --help"
			$i --help
			echo
		done
	else
		# Print help message
		echo "Tip: You can use $(font yellow)xhelp$(font off) in place of xmpphelp."
		# List off all commands
		font bold
		echo "Valid commands:"
		font off
		for i in ${XMPP_CMDS[@]}; do
			if [ "$i" = "," ]; then
				echo
			else
				echo "	$i"
			fi
		done
	fi
}

# Set whether xml pretty printing is on or off
pretty() {
	local opt=$1

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: pretty [on | off]"
		echo "Set whether xml pretty printing is on or off"
		return 0
	fi

	case $opt in
		"")
			(( xml_pretty_enable )) && echo on || echo off
			;;
		on|1)
			xml_pretty_enable=1
			;;
		off|0)
			xml_pretty_enable=0
			;;
		*)
			pretty --help
			return 1
			;;
	esac

}

# Print out the active jid
get_jid() {
	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_jid"
		echo "Print out the active JID being used"
		return 0
	fi

	echo ${xmpp_user}@${xmpp_host}
}

# Set the active jid
set_jid() {
	local jid=( ${1/@/ } ) # separate at @
	jid=( ${jid[@]/\// } ) # further separate at /

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: set_jid <jid>"
		echo "Set the active JID to use"
		return 0
	fi

	# Check that we have exactly two parts
	if [ ${#jid[@]} -lt 2  -o  ${#jid[@]} -gt 3 ]; then
		echo "Error - Invalid jid"
		return 1
	fi

	xmpp_user=${jid[0]}
	xmpp_host=${jid[1]}
	# future support of resources starts here
	#xmpp_res=${jid[2]}
}

# Print out the active password
get_pass() {
	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_pass"
		echo "Print out the active password being used"
		return 0
	fi

	echo ${xmpp_pass}
}


# Set the active password
set_pass() {
	local password="$1"

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: set_pass <password>"
		echo "Set the active password to use"
		return 0
	fi

	xmpp_pass="${password}"
}

# Print out the active pubsub host
get_pubsub() {
	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_pubsub"
		echo "Print out the active pubsub host being used"
		return 0
	fi

	echo ${xmpp_pubsub}
}

# Set the active pubsub host
set_pubsub() {
	local pubsub=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: set_pubsub < - | <pubsub_host> >"
		echo "Set the active pubsub host to use"
		echo "       Specify \"-\" to use the default pubsub for your host"
		return 0
	fi

	if [ "$pubsub" = "-" ]; then
		xmpp_pubsub="pubsub.${xmpp_host}"
	else
		xmpp_pubsub=${pubsub}
	fi
}

# Show all current configuration settings
get_config() {

	# check args
	if (( $# < 0 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_config"
		return 0
	fi

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
	echo "pubsub=$xmpp_pubsub"
	font bold
	echo "# Extra Info #"
	font off
	echo -n "Run "
	font yellow
	echo -n "xmpphelp"
	font off
	echo " to show allowed commands."
	echo -n "Run any command with "
	font yellow
	echo -n "--help"
	font off
	echo " to get usage information"
	echo "xmpptools and xmppcmd version $XMPPCMD_VERSION"
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
# publish <node> <item_id> < item_content | - >
publish() {
	local node=$1
	local item_id=$2

	# check args
	if (( $# < 3 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: publish <node> <item_id> < item_content | - > "
		echo "Publish content to a pubsub node"
		echo "       Using the \"-\" indicates using stdin as item_content"
		return 0
	fi

	shift 2
	{
		# Emit the beginning of the publish message
		#cat | tr -d "\n" <<-EOF
		cat <<-EOF
		<pubsub xmlns='http://jabber.org/protocol/pubsub'>
			<publish node='$node'>
				<item id='$item_id'>
		EOF
		#echo -n "

		# Emit content to publish
		if [ "$*" = "-" ]; then
			# removes any beginning spaces or tab and trailing spaces and tabs
			#cat | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d "\n"
			cat
		else
			echo -n $*
		fi

		# Emit the ending of the publish message
		#cat | tr -d "\n" <<-EOF
		cat <<-EOF
				</item>
			</publish>
		</pubsub>
		EOF
	} \
		| send_stanza_iq set
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
		echo "Subscribe \"jid\" to the pubsub \"node\""
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
		echo "Unsubscribe \"jid\" from the pubsub \"node\""
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
		echo "Dump all nodes on the pubsub host"
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
		echo "Usage: get_subscribers <node>" >&2
		echo "Get a list of subscribers of a given node" >&2
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

# Get item(s) for a node
# get_item <node> <item_id> [item_id2 [item_id3...]]
get_item() {
	local node=$1

	# check args
	if (( $# < 1 )) || [[ "$1" =~ --help ]] || [[ "$1" =~ -h ]]; then
		echo "Usage: get_item <node> <item_id> [item_id2 [item_id3...]]"
		return 0
	fi

	# Add in secret shortcut to get all items
	# Just type: get_items <node>
	if (( $# == 1 )); then
		get_items $node
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

##########################################################################
##########################################################################

complete -W "${XMPP_CMDS[*]/,/}" xmpphelp
complete -W "${XMPP_CMDS[*]/,/}" xhelp
complete -W "on off" pretty
complete -W "owner" stanza_pubsub

##########################################################################
##########################################################################


# Unset all DEFAULT_XMPP_* Settings for Reimporting xmpprc #
unset DEFAULT_XMPP_USER
unset DEFAULT_XMPP_PASS
unset DEFAULT_XMPP_HOST
unset DEFAULT_XMPP_PUBSUB

# Fetch Default Settings - local xmpprc has override priority #
if [ -f "$HOME/.config/xmpprc" ]; then
	. $HOME/.config/xmpprc
fi
if [ -f xmpprc ]; then
	. xmpprc
fi

# Set DEBUG to default if environment doesn't set it
DEBUG=${DEBUG:-$DEFAULT_DEBUG}

# First try to set user, host, pass, and pubsub from environment variable, #
# then fallback on default values from the last xmpprc file sourced        #
JID=( ${XMPP_JID/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$DEFAULT_XMPP_USER}
xmpp_pass=${XMPP_PASS:-$DEFAULT_XMPP_PASS}
xmpp_host=${JID[1]:-$DEFAULT_XMPP_HOST}
# DEFAULT_XMPP_PUBSUB is implicit if DEFAULT_XMPP_HOST is set
if [ -n "$DEFAULT_XMPP_HOST" ]; then
	# set implicit if default was unset
	DEFAULT_XMPP_PUBSUB=${DEFAULT_XMPP_PUBSUB:-pubsub.$DEFAULT_XMPP_HOST}
fi
xmpp_pubsub=${XMPP_PUBSUB:-$DEFAULT_XMPP_PUBSUB}

# Now, override user, host, pass from arguments if available #
JID=( ${1/@/ } ) ## break up jid into user and host
xmpp_user=${JID[0]:-$xmpp_user}
xmpp_pass=${2:-$xmpp_pass}
xmpp_host=${JID[1]:-$xmpp_host}
xmpp_pubsub=${3:-$xmpp_pubsub}

# Runtime Settings #
XML_PRETTYPRINT_UTIL="xmllint"
XMPPTOOLS_DIR=`dirname $BASH_SOURCE`
xml_pretty_enable=1

# Source font library #
. $XMPPTOOLS_DIR/font_simple.sh

# Print Configuration Settings #

if (( DEBUG > 0 )); then
	get_config
fi

# Check for Utilities Needed #

# we now require xmllint for flattening xml before sending
if ! hash xmllint &>/dev/null; then
	font red bold >&2
	echo "Error - xmllint (Deb pkg libxml2-utils) is not installed">&2
	echo "      - this is required for processing xml before sending">&2
	font off >&2
fi

case $XML_PRETTYPRINT_UTIL in
	xmllint)
		if ! hash xmllint &>/dev/null; then
			font red bold >&2
			echo "Error - xmllint (Deb pkg libxml2-utils) is not installed">&2
			echo "      - XML pretty printing will be disabled">&2
			font off >&2
			XML_PRETTYPRINT_UTIL=cat
		fi
		;;
	*)
		if ! hash $XML_PRETTYPRINT_UTIL &>/dev/null; then
			font red bold >&2
			echo "Error - $XML_PRETTYPRINT_UTIL cannot be found">&2
			echo "      - XML pretty printing will be disabled">&2
			font off >&2
			XML_PRETTYPRINT_UTIL=cat
		fi
		;;
esac

if [ ! -e $XMPPTOOLS_DIR/xmppsend ]; then
	font red bold >&2
	echo "Error - xmppsend is not built">&2
	echo "      - run make">&2
	font off >&2
fi


# vim: syntax=sh ts=4
