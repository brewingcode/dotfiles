# OSX-only stuff. Abort if not OSX.
is_osx || return 1

ulimit -n 10240

PATH=`/usr/bin/paste -d ":" -s - << EOF
/usr/local/bin
$PATH
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

code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

# prettify Chrome's "copy as curl" command line
function recurl {
  pbpaste | perl -lpe '
    s/^curl ('\''.*?'\'')/curl /;
    $_ .= " \\\n $1";
    s/ -H/ \\\n  -H/g;
  ' | pbcopy
}

alias clc="fc -ln -1 | awk '{\$1=\$1}1' | pbcopy"

function vjq {
  tmp=/tmp/$(openssl rand -hex 16)
  pbpaste > $tmp
  vim $tmp
  echo "wrote json to $tmp"
  jq . < $tmp
}

# switch java versions via OSX's java_home
jvm() {
  version=${1:-1.6}
  export JAVA_HOME=$(/usr/libexec/java_home -v $version)
}

# open a url in Chrome with minimal UI
minchr() {
  [ -z "$1" ] && { echo "url required" >&2; return 1; }
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --app="$1"
}

