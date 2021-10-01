# Bootstrap for dotfiles: source this file.
#
# 1. add "bin" to the PATH env var
# 2. source everything in the "source" dir
# 3. link everything in "links" into $HOME, but only if it doesn't already
#    exist (set RELINK_DOTFILES=1 to override)
# 4. copy everything in "copy" into $HOME, but only if it doesn't already
#    exist (set RECOPY_DOTFILES=1 to override)

initial_dir=$(pwd)

export DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -d "$DOTFILES" ] || { printf "DOTFILES=%s does not point to a directory" "$DOTFILES" 1>&2; exit 1; }

is_osx() {
  [[ "$OSTYPE" =~ ^darwin ]] || return 1
}
is_wsl() {
  [ -d /mnt/c ]
}
is_ubuntu() {
  is_wsl && return 1
  [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]] || return 1
}

# add binaries into the path
export PATH="$DOTFILES/bin:$PATH"

# make splat smarter
shoptions=$(shopt -p)
shopt -s dotglob nullglob

# source all the things....but source some things after others
cd "$DOTFILES/source" || exit 2
for f in *; do
  #[[ ! "$f" =~ ^(misc|prompt|history)$ ]] && echo "$f" && time source "$f"
  [[ ! "$f" =~ ^(misc|prompt|history)$ ]] && source "$f"
done
for f in misc prompt history; do
  #echo "$f" && time source "$f"
  source "$f"
done

# make sure links exist
cd "$DOTFILES/link" || exit 3
for f in *; do
  if [ ! -e "$HOME/$f" ] || [ -n "$RELINK_DOTFILES" ]; then
    ln -fs "$DOTFILES/link/$f" "$HOME/$f"
  fi
done

# make sure files have been copied, but only if they don't exist already
cd "$DOTFILES/copy" || exit 4
for f in *; do
  if [ ! -e "$HOME/$f" ] || [ -n "$RECOPY_DOTFILES" ]; then
    cp -r "$f" "$HOME/$f"
  fi
done

eval "$shoptions"
cd "$initial_dir"
