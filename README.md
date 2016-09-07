<img align="left" src="https://github.com/linux4life798/xmpptools/blob/master/res/XMPPTools_logo.png" width="128">

# Description
This repository was intended to contain tools that allow you to
quickly test and automate XMPP related things.

The sourceable bash script `xmppcmd.bash` allows you to quickly
interact with raw xmpp or xmpp pubsub from the bash command line(or scripts).
Once sourced in bash, the function can be interacted with like shell
native commands. The functions are easily discoverable using the
`xmpphelp` command. The usage of such functions can be learned by
using the `-h` flag in the command arguments.

The other goal of this project was to create a tool that allowed the
user to easily interact and learn the xmpp protocol. This is why the
default debugging level is configured to emit the XML that is being
sent and received. The tool automatically formats and color codes the
XML stanzas in the terminal.

Looking though the script, you will notice that the functions build on
each other in a structured manor. The level of abstraction from raw
xmpp/xml to pubsub operations has been built up using the pipe operation.
This same strategy can be used to create compact user defined functions.
Users can add new functionality on-the-fly by combining parts of the core
xmpp functions with readily accessible coreutils.

* xmppcmd.bash - BASH sourceable library of functions to control XMPP and XEP-0060
* xmppsend.c   - The utility program that is used to send stanzas to the XMPP server and wait for responses
* xmpprecv.c   - The utility program that is used to receive stanzas from the XMPP server

# Features
* Pretty print XML output
* BASH tab completions for node names and node item names (queries pubsub in background)
* Global config and local config options

# Setup

1. Compilation <br />
  You need to build the *xmppsend* and *xmpprecv* executables for use by the xmppcmd.bash library.
    * The build system assumes that you have the development files for libstrophe installed.
      - To install these on Debian, do a `sudo apt-get install libstrophe-dev`.
      - To install these on OSX with homebrew, do a `brew install libstrophe`
        and uncomment the two lines noted in the Makefile.
    * A simple `make` in the xmpptools directory will build the binaries. If everything goes ok, you should see 
      two new binaries, xmppsend and xmpprecv.

2. Setting Defaults [optional] <br />
  Setting the default JID and password makes using this tool even more convenient.
  You can set a default JID and password in the xmpprc file.
  The variables of interest are `DEFAULT_XMPP_USER`, `DEFAULT_XMPP_HOST`, and `DEFAULT_XMPP_PASS`.
  You will need to separate the JID into the USER and HOST parts.

  Of course, I am obligated to tell you that saving passwords in plain text is a bad idea, so take necessary precautions.

# Basic Usage

One of the quickest ways to initialize the library is to supply the JID and Password on the commandline, as in the following example.

## Step 1
Load and initialize the utility.

```bash
. xmppcmd.bash "craig@example.com" "mypassword"
```

## Step 2
Run any command in the library.

Example:
```bash
get_nodes
```

---

# How To*s / Examples

Below, I will show a few common commands.
Look in the `examples` directory for scripting examples.

## Get list of commands
```bash
xmpphelp
```
Note: Running any command with the `-h` argument will present it's usage options.

## Create a node
```bash
create craignode
```

## Publish to node
```bash
publish craignode RandomItemId7 "<entry><head><title>Amazing Title</title></head><body>Some good website content</body></entry>"
```

## Change JID
```bash
. xmppcmd.bash bob
```

## Subscribe to a node
```bash
subscribe craignode
```

## Get subscription list for a node
```bash
get_subscribers craignode
```

## Remove subscriber from owned node
```bash
set_subscribers craignode tom none
```

## Get affiliations of a node
```bash
get_affiliates craignode
```

## Change subscriber to owner
```bash
set_affiliations craignode tom owner
```

## Get vCard for jid
```bash
get_vcard tom
```

## Set vCard for logged in JID
```bash
set_vcard <<-EOF
<vCard xmlns="vcard-temp">
  <FN>Craig Hesling</FN>
  <EMAIL>
    <USERID>craig@example.com</USERID>
  </EMAIL>
</vCard>
EOF
```
# Dev Notes

* Future work may include integrating more xml parsing functionality.
* Future work may include more serious bash completions

Pull requests are MORE than welcome. There are still so many XMPP functions and extensions to include.
