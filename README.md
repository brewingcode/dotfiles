# Dotfiles

My OSX / Ubuntu dotfiles.

## How to use

Clone this repo somewhere (we will assume `~/.dotfiles`) and then add the
following to your shell initialization file. If you run bash, this is
`.bashrc`. If you run some other shell, god help you.

    export DOTFILES=~/.dotfiles
    source "$DOTFILES/init.sh"

To update your current shell, simply re-run your shell initialization (`.
~/.bashrc`). Any future shells you open will automatically pick up these
changes.

