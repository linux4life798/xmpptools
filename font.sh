#!/bin/bash
# Author: Craig Hesling
# Date: July 26, 2013

###############################
## General Display Functions ##
###############################

declare -A FONT_FG_COLOR=(
                        [black]=30
                        [red]=31
                        [green]=32
                        [yellow]=33
                        [blue]=34
                        [magenta]=35
                        [cyan]=36
                        [white]=37
                        [def]=39
                        [-]=39
                    )
declare -A FONT_STYLE=(
                        [bold]=1
                        [italic]=3
                        [underline]=4
                        #[blink-slow]=5
                        #[blink-fast]=6
                        [swap]=7
                        [conceal]=8
                        [cross]=9
                        [def]=10
                        [-]=10
                )
declare -A FONT_BG_COLOR=(
                        [black]=40
                        [red]=41
                        [green]=42
                        [yellow]=43
                        [blue]=44
                        [magenta]=45
                        [cyan]=46
                        [white]=47
                        [def]=49
                        [-]=49
                    )

# Add some aliases
FONT_FG_COLOR[purple]=${FONT_FG_COLOR[magenta]}
FONT_STYLE[b]=${FONT_STYLE[bold]}
FONT_STYLE[i]=${FONT_STYLE[italic]}
FONT_STYLE[u]=${FONT_STYLE[underline]}
FONT_BG_COLOR[purple]=${FONT_BG_COLOR[magenta]}

# font [foreground_color|-] [style|-] [background_color|-]
# 	ex1(turn off fonts):     font
# 	ex2a(green with italic): font green italic
# 	ex2a(green with italic): font green; font - italic
# 	ex3(bold and underline): font - b; font - u
font() {
	if [ "$1" == "--help" ]; then
		echo "Author: Craig Hesling" >&2
		echo "I'm a shell library" >&2
		return 1
	fi

	local options=""

	# get user selection and remove optional space holders(-)
	local fgcolor=${1/-/} style=${2/-/} bgcolor=${3/-/} # use replacement so that you could have multiple -'s

	if [ -n "$fgcolor" ]; then options="${FONT_FG_COLOR[$fgcolor]}"; fi
	if [ -n "$style" ];   then options+=";${FONT_STYLE[$style]}"; fi
	if [ -n "$bgcolor" ]; then options+=";${FONT_BG_COLOR[$bgcolor]}"; fi

	printf "\033[${options}m"
}

red_on() {
	printf "\033[31m"
}
green_on() {
	printf "\033[32m"
}
yellow_on() {
	printf "\033[33m"
}
blue_on() {
	printf "\033[34m"
}

font_off() {
	printf "\033[m"
}
