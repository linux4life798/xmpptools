#!/bin/bash
# This script can be used to simple actuate a MIO node in one line
#
# Example: ./mioact.sh bob@sensor.andrew.cmu.edu bobspassword 03a4fdc0-dce5-11e4-ba47-d7d35fb6b294 "Door State" 1
#
# Craig Hesling <craig@hesling.com>

MIOTOOLS_DIR=`dirname $BASH_SOURCE` # find my directory
export DEBUG=1

jid=$1
pass=$2
pubsub=$6

node=$3
transducer=$4
value=$5

# User and password can be defined in the local xmpprc or arguments
# to the library.

# Using xmpprc or supplied args
. $MIOTOOLS_DIR/mio.bash "$jid" "$pass" $pubsub #&> /dev/null

echo "### Executing on $(printf "%20s" "`date`") ###"
echo \$ mio_act \""$node"\" \""$transducer"\" \""$value"\"
echo "#################################################"
echo
mio_act "$node" "$transducer" "$value"
