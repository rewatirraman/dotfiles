export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\W\[\033[m\]\$ "

#export PATH=$PATH:~/usr/bin
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/usr/lib
#export C_INCLUDE_PATH=$C_INCLUDE_PATH:~/usr/include
#export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:~/usr/include

# To have colors for ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

export TERM=xterm-256color

# shorten cmnd line prompt's current dir
export PROMPT_DIRTRIM=2
unset LC_CTYPE

# Source global definitions
#if [ -f /etc/bashrc ]; then
# . /etc/bashrc
#fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
. /etc/bash_completion
fi

# Disable the bell
# if [[ $iatest > 0 ]]; then bind "set bell-style visible"; fi

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=10000

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# Edit this .bashrc file
alias ebrc='vi ~/.bashrc'
alias sbrc='source ~/.bashrc'

# Use Ubuntu themed dircolors
if [ -e "${BYOBU_PREFIX}/share/byobu/profiles/dircolors" ]; then
    dircolors "${BYOBU_PREFIX}/share/byobu/profiles/dircolors" > "$BYOBU_RUN_DIR/dircolors"
    . "$BYOBU_RUN_DIR/dircolors"
fi


if [ -x /usr/bin/dircolors ]; then
     test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias cp='cp -i'
alias mv='mv -iv'
alias mkdir='mkdir -p -v'
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels

alias ls='ls -Fh --color=auto'
alias ll='ls -lrth'
alias lla='ls -lrthA'                       # Preferred 'ls list' implementation
alias vi='/usr/bin/vi'

# alias chmod commands
alias chmod='chmod -R '

chmod_per() {
    sp="\t\t\t\t"
    echo -e "$sp 0 -> 000 -> ---"
    echo -e "$sp 1 -> 001 -> --x"
    echo -e "$sp 2 -> 010 -> -w-"
    echo -e "$sp 3 -> 011 -> -wx"
    echo -e "$sp 4 -> 100 -> r--"
    echo -e "$sp 5 -> 101 -> r-x"
    echo -e "$sp 6 -> 110 -> rw-"
    echo -e "$sp 7 -> 111 -> rwx"
}

# To see if a command is aliased, a file, or a built-in command
alias find_command="type -t"

# SHA1
alias sha1='sha1sum'

alias cpu="grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}' | awk '{printf(\"%.1f\n\", \$1)}'"

# Remove all non-ascii chars from a file
remove_non_ascii() {
    cp $1 tmpfile && LC_ALL=C tr -dc '\0-\177' <tmpfile >$1 && rm tmpfile
}

# grep the index of .c .h files from the diffs
grepchFileIndex () {
    cat $1 | grep "^Index.*[\.adp][cdhmlp]$" | awk '{print $2}'
}

extract() {
   dr_name=`echo $1 | awk '{split($0, a, "."); print a[1]}'` 
   mkdir $dr_name
   tar xzf $1 -C $dr_name
}


#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
extract2 () {

            if [ -f $1 ] ; then
              case $1 in
                *.tar.bz2)   tar xjf $1     ;;
                *.tar.gz)    tar xzf $1     ;;
                *.bz2)       bunzip2 $1     ;;
                *.rar)       unrar e $1     ;;
                *.gz)        gunzip $1      ;;
                *.tar)       tar xf $1      ;;
                *.tbz2)      tar xjf $1     ;;
                *.tgz)       tar xzf $1     ;;
                *.zip)       unzip $1       ;;
                *.Z)         uncompress $1  ;;
                *.7z)        7z x $1        ;;
                *)     echo "'$1' cannot be extracted via extract()" ;;
                 esac
            else
               echo "'$1' is not a valid file"
            fi
}

function __setprompt
{
<<comment_this
    local LAST_COMMAND=$? # Must come first!

    # Define colors
    local LIGHTGRAY="\033[0;37m"
    local WHITE="\033[1;37m"
    local BLACK="\033[0;30m"
    local DARKGRAY="\033[1;30m"
    local RED="\033[0;31m"
    local LIGHTRED="\033[1;31m"
    local GREEN="\033[0;32m"
    local LIGHTGREEN="\033[1;32m"
    local BROWN="\033[0;33m"
    local YELLOW="\033[1;33m"
    local BLUE="\033[0;34m"
    local LIGHTBLUE="\033[1;34m"
    local MAGENTA="\033[0;35m"
    local LIGHTMAGENTA="\033[1;35m"
    local CYAN="\033[0;36m"
    local LIGHTCYAN="\033[1;36m"
    local NOCOLOR="\033[0m"

    # Show error exit code if there is one
    if [[ $LAST_COMMAND != 0 ]]; then
    # PS1="\[${RED}\](\[${LIGHTRED}\]ERROR\[${RED}\])-(\[${LIGHTRED}\]Exit Code \[${WHITE}\]${LAST_COMMAND}\[${RED}\])-(\[${LIGHTRED}\]"
    PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
    if [[ $LAST_COMMAND == 1 ]]; then
    PS1+="General error"
    elif [ $LAST_COMMAND == 2 ]; then
    PS1+="Missing keyword, command, or permission problem"
    elif [ $LAST_COMMAND == 126 ]; then
    PS1+="Permission problem or command is not an executable"
    elif [ $LAST_COMMAND == 127 ]; then
    PS1+="Command not found"
    elif [ $LAST_COMMAND == 128 ]; then
    PS1+="Invalid argument to exit"
    elif [ $LAST_COMMAND == 129 ]; then
    PS1+="Fatal error signal 1"
    elif [ $LAST_COMMAND == 130 ]; then
    PS1+="Script terminated by Control-C"
    elif [ $LAST_COMMAND == 131 ]; then
    PS1+="Fatal error signal 3"
    elif [ $LAST_COMMAND == 132 ]; then
    PS1+="Fatal error signal 4"
    elif [ $LAST_COMMAND == 133 ]; then
    PS1+="Fatal error signal 5"
    elif [ $LAST_COMMAND == 134 ]; then
    PS1+="Fatal error signal 6"
    elif [ $LAST_COMMAND == 135 ]; then
    PS1+="Fatal error signal 7"
    elif [ $LAST_COMMAND == 136 ]; then
    PS1+="Fatal error signal 8"
    elif [ $LAST_COMMAND == 137 ]; then
    PS1+="Fatal error signal 9"
    elif [ $LAST_COMMAND -gt 255 ]; then
    PS1+="Exit status out of range"
    else
    PS1+="Unknown error code"
    fi
    PS1+="\[${DARKGRAY}\])\[${NOCOLOR}\]\n"
    else
    PS1=""
    fi

    PS1=""
    # Date
    PS1+="\[${DARKGRAY}\](\[${CYAN}\]\$(date +%a) $(date +%b-'%-m')" # Date
    PS1+="${BLUE} $(date +'%-I':%M:%S%P)\[${DARKGRAY}\])-" # Time

    # User and server
    local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
    local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
    if [ $SSH2_IP ] || [ $SSH_IP ] ; then
    #PS1+="(\[${RED}\]\u@\h"    # shows username
    PS1+="(\[${RED}\]\h"        # hide username
    else
    PS1+="(\[${RED}\]\u"
    fi

    # Current directory
    PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${DARKGRAY}\])-"

        # Number of files
    PS1+="(\[${GREEN}\]\$(/bin/ls -A -1 | /usr/bin/wc -l)\[${DARKGRAY}\])"

    # Skip to the next line
    # PS1+="\n"

    if [[ $EUID -ne 0 ]]; then
    PS1+="\[${GREEN}\]$\[${NOCOLOR}\] " # Normal user
    else
    PS1+="\[${RED}\]$\[${NOCOLOR}\] " # Root user
    fi

    # PS2 is used to continue a command using the \ character
    PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

    # PS3 is used to enter a number choice in a script
    PS3='Please enter a number from above list: '

    # PS4 is used for tracing a script in debug mode
    PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
comment_this
}
PROMPT_COMMAND='__setprompt'

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
