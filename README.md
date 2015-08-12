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
