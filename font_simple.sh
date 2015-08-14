# Version: 1
# Created: 10/30/2014
# Updated: 12/11/2014 (just removed the IFVERB)
# Updated: 8/14/2015 (checks that the BASH version is at least 4)
# Author:  Craig Hesling
## Standard Font Used In Scripts ##

# Colors and Fonts #
OF="\E[m"
RD="\E[31m"
GN="\E[32m"
YL="\E[33m"
BL="\E[34m"

B="\E[01m" # bold
U="\E[04m" # underscore
I="\E[07m" # invert colors

if [ "$(echo $BASH_VERSION | cut -d '.' -f 1)" -ge 4 ]; then
	declare -g -A FONTS=( )
	FONTS=(              \
		[off]="$OF"      \
		[red]="$RD"      \
		[green]="$GN"    \
		[yellow]="$YL"   \
		[blue]="$BL"     \
		[bold]="$B"      \
		[underline]="$U" \
		[invert]="$I"    \
	)
	ASSOC_SUPPORT=1
else
	ASSOC_SUPPORT=0
	echo "font_simple.sh: Error - BASH version does not support associative arrays" >&2
fi

# Font Control #

# Set terminal font options
# Arguments are a series of options defined in FONTS array
# Ex. font bold blue
# Ex. font off
font()
{
	# do nothing for old versions of BASH
	if [ $ASSOC_SUPPORT -lt 1 ]; then
		return 1
	fi

	for opt; do
		printf "${FONTS[$opt]}"
	done

	return 0
}

# vim: syntax=sh ts=4
