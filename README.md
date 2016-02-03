# Description
This repository was intended to contain tools that allow you to quickly test and automate XMPP related things.

* xmppcmd.bash - BASH sourceable library of functions to control XMPP and XEP-0060
* xmppsend.c   - The utility program that is used to send stanzas to the XMPP server and wait for responses
* xmpprecv.c   - The utility program that is used to receive stanzas from the XMPP server

# Setup

1. Compilation <br />
  You need to build the xmppsend and xmpprecv executables for use by the xmppcmd.bash library.
    * The build system assumes that you have the development files for libstrophe installed. On Debian, 
      this is the `libstrophe-dev` package. To install these on Debian, do a `sudo apt-get install libstrophe-dev`.
    * A simple `make` in the xmpptools directory will build the binaries. If everything goes ok, you should see 
      two new binaries, xmppsend and xmpprecv.

2. Setting Defaults [optional] <br />
  Setting the default JID and password makes using this tool even more convientient.
  You can set a default JID and password near the top of the main xmppcmd.bash file.
  The variables of interest are `DEFAULT_XMPP_USER`, `DEFAULT_XMPP_HOST`, and `DEFAULT_XMPP_PASS`.
  You will need to separate the JID into the USER and HOST parts.

  Of course, I am obligated to tell you that saving passwords in plain text is a bad idea, so watch your back.

# Basic Usage

## Step 1
Load and initialize the utility.

```bash
. xmppcmd.bash
```

## Step 2
Run any command in the library.

Example:
```bash
get_nodes
```

---

# How To*s / Examples

## Get list of commands
```bash
xmpphelp
```
Note: Running any command with -h argument will present it's usage options.

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
