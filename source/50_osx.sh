# OSX-only stuff. Abort if not OSX.
is_osx || return 1

PATH=`/usr/bin/paste -d ":" -s - << EOF
/opt/local/bin
/opt/local/sbin
/usr/local/bin
$PATH
/opt/local/Library/Frameworks/Python.framework/Versions/2.7/bin
/opt/local/lib/mysql56/bin
/opt/local/libexec/perl5.16
EOF`
export PATH

# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# Make 'less' more.
[[ "$(type -P lesspipe.sh)" ]] && eval "$(lesspipe.sh)"

# Start ScreenSaver. This will lock the screen if locking is enabled.
alias ss="open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"

# restart wifi
alias rswifi="networksetup -setairportpower en0 off ; networksetup -setairportpower en0 on"

# restart a Macports daemon
function portre {
  sudo port unload $1
  sudo port load $1
}

# list all launchd's
function launchds {
  find /Library/Launch* /System/Library/Launch* $HOME/Library/Launch* -ls | perl -lpe 's/^\d+\s+\d+\s+//'
}

# fire up boot2docker, and prepare shell for running commands in it
function dockup {
  boot2docker up >/dev/null 2>&1
  eval "$(boot2docker shellinit 2>/dev/null)" >/dev/null 2>&1
}

function brewup {
  export PATH="/opt/homebrew/bin:$PATH"
}

