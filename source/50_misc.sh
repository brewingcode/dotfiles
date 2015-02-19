# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

export GREP_OPTIONS='--color=auto'

# Prevent less from clearing the screen while still showing colors.
export LESS=-XR

# Set the terminal's title bar.
function titlebar() {
  echo -n $'\e]0;'"$*"$'\a'
}

# SSH auto-completion based on entries in known_hosts.
if [[ -e ~/.ssh/known_hosts ]]; then
  complete -o default -W "$(cat ~/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi

# Disable ansible cows }:]
export ANSIBLE_NOCOWS=1

export PYTHONPATH=$DOTFILES/lib

# find, and then sum the size of everything in KB
function finds {
  find "$@" -ls | awk '{X+=$7} END {print X/1000}'
}

# truncate stdin exactly to term width
function trunc {
  cut -c -$(tput cols)
}

# grep -C<x> does stupid things in its output, fix them
#   * the same line might be printed twice
#   * "--" twice in a row is dumb
function cgrep {
  grep -n "$@" | perl -lne '
    $x{$1} = $3 if /^(\d+)(:|-)(.*)/;
    END {
      for (sort {$a <=> $b} keys %x ) {
        print "--" if $p and $_ - $p > 1;
        print $x{$_};
        $p = $_
      }
    }
  '
}

function hex2bin {
  perl -e '
    for $arg (@ARGV) {
      $hexlen = length $arg;
      $binlen = $hexlen * 4;
      print unpack "B$binlen", pack "H$hexlen", $arg;
      print "\n";
    }
  ' "$@"
}

function vimm {
  vim -u /dev/null $*
}
