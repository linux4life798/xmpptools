#!/bin/bash
# A set of utilites to make MIO operations easy with xmpptools
#
# Craig Hesling <craig@hesling.com>
# September 2, 2016

# Import xmpptools
. xmppcmd.bash $@

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

# Setup BASH Completions #

if (( COMPLEX_COMPLETIONS_ENABLED )); then
	complete -F _single_node meta_get
	complete -F _single_node meta_set
	complete -F _single_node meta_edit
else
	{
	complete -r meta_get
	complete -r meta_set
	complete -r meta_edit
	} 2> /dev/null
fi

# vim: syntax=sh ts=4
