# Bootstrap for dotfiles: source this file.
#
# 1. add "bin" to the PATH env var
# 2. source everything in the "source" dir
# 3. link everything in "links" into $HOME, but only if it doesn't already
#    exist (set RELINK_DOTFILES=1 to override)
# 4. copy everything in "copy" into $HOME, but only if it doesn't already
#    exist (set RECOPY_DOTFILES=1 to override)

initial_dir=$(pwd)

export DOTFILES=$(cd "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)
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

export -f is_osx
export -f is_wsl
export -f is_ubuntu

# add binaries into the path
export PATH="$DOTFILES/bin:$DOTFILES/best/bin:/usr/local/opt/sqlite/bin:$HOME/.cargo/bin:$PATH"

if [ -n "$BASH_VERSION" ]; then
  shoptions=$(shopt -p)
  shopt -s dotglob nullglob
else
  shoptions=$(setopt -p)
  setopt GLOB_DOTS NULL_GLOB
fi

# source all the things....but source some things after others
cd "$DOTFILES/source" || exit 2
for f in *; do
  #[[ ! "$f" =~ ^(misc|prompt|history|games)$ ]] && echo "$f" && time source "$f"
  [[ ! "$f" =~ ^(misc|prompt|history|games)$ ]] && source "./$f"
done
for f in misc prompt history games; do
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
