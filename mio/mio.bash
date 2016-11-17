#!/bin/bash
# A set of utilites to make MIO operations easy with xmpptools
#
# Craig Hesling <craig@hesling.com>
# September 2, 2016

# Runtime Settings #
XMPPTOOLS_DIR=`dirname $BASH_SOURCE`/.. # find my directory

# Import xmpptools
. $XMPPTOOLS_DIR/xmppcmd.bash $@

# TODO: Fix timestamp
timestamp() {
	echo 2016-09-01T16:47:06.173118-0500
}

# meta_get craignode > meta.xml
meta_get() {
	local node=$1
	get_item $node meta \
	| xmllint --format --xpath "/*[local-name() = 'iq']/*[local-name() = 'pubsub']/*[local-name() = 'items']/*[local-name() = 'item']/*[local-name() = 'meta']" - \
	| xml_prettyprint
	echo
}

# cat meta.xml | meta_set craignode
meta_set() {
	local node=$1
	publish $node meta -
}

# meta_edit craignode
meta_edit() {
	local node=$1

	local tmp=`tempfile /tmp/metaXXX.xml`
	meta_get $node > $tmp
	vi $tmp
	cat $tmp | meta_set $node
}

# ref_get craignode > ref.xml
ref_get() {
	local node=$1
	get_item $node references \
	| xmllint --format --xpath "/*[local-name() = 'iq']/*[local-name() = 'pubsub']/*[local-name() = 'items']/*[local-name() = 'item']/*[local-name() = 'references']" - \
	| xml_prettyprint
	echo
}

# cat ref.xml | ref_set craignode
ref_set() {
	local node=$1
	publish $node references -
}

# ref_edit craignode
ref_edit() {
	local node=$1

	local tmp=`tempfile /tmp/refXXX.xml`
	ref_get $node > $tmp
	vi $tmp
	cat $tmp | ref_set $node
}

# storage_get craignode > storage.xml
storage_get() {
	local node=$1
	get_item $node storage \
	| xmllint --format --xpath "/*[local-name() = 'iq']/*[local-name() = 'pubsub']/*[local-name() = 'items']/*[local-name() = 'item']/*[local-name() = 'addresses']" - \
	| xml_prettyprint
	echo
}

mio_get() {
	local node=$1
	get_item $node meta references storage
}

# mio_pub 7dd74af4-ac4f-11e6-9e0c-180373458145 Temperature 23.78
mio_pub() {
	local node=$1
	local transducer="$2"
	local value="$3"
	local timestamp=`timestamp`

	eof \
	| stanza transducerData "value=$value" "name=$transducer" "timestamp=$timestamp" \
	| publish $node "_${transducer}" -

	#<transducerData value="1.000000" name="Door State" timestamp="2016-09-01T16:47:06.173118-0500"/>
}

# mio_act 03a4fdc0-dce5-11e4-ba47-d7d35fb6b294 "Door State" 1
mio_act() {
	local node=$1
	local transducer="$2"
	local value="$3"
	local timestamp=`timestamp`

	eof \
	| stanza transducerSetData "value=$value" "name=$transducer" "timestamp=$timestamp" \
	| publish "${node}_act" "_${transducer}" -

	#<transducerSetData value="1" name="Door State" timestamp="2016-09-01T17:47:05.078179-0400"/>
}

# Setup BASH Completions #

if (( COMPLEX_COMPLETIONS_ENABLED )); then
	complete -F _single_node meta_get
	complete -F _single_node meta_set
	complete -F _single_node meta_edit
	complete -F _single_node ref_get
	complete -F _single_node ref_set
	complete -F _single_node ref_edit
	complete -F _single_node storage_get
	#complete -F _single_node_item mio_publish
	complete -F _single_node mio_pub
	complete -F _single_node mio_act
else
	{
	complete -r meta_get
	complete -r meta_set
	complete -r meta_edit
	complete -r ref_get
	complete -r ref_set
	complete -r ref_edit
	complete -r storage_get
	complete -r mio_pub
	complete -r mio_act
	} 2> /dev/null
fi

# vim: syntax=sh ts=4
