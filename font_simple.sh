# Version: 1
# Created: 10/30/2014
# Updated: 12/11/2014 (just removed the IFVERB)
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

# Font Control #

# Set terminal font options
# Arguments are a series of options defined in FONTS array
# Ex. font bold blue
# Ex. font off
font()
{
	for opt; do
		#IFVERB2 echo "font: $opt" >&2
		printf "${FONTS[$opt]}"
	done
}

# vim: syntax=sh ts=4
