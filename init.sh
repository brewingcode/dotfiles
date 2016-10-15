# bootstrap for dotfiles: source this file
DOTFILES=$(pwd)/$(dirname "$_")
[ -d "$DOTFILES" ] || { echo "\$DOTFILES=$DOTFILES does not point to a directory" >&2; return 1; }

# OS detection: some things are only OSX, others are only Ubuntu, but
# both are in the minority
is_osx() {
  [[ "$OSTYPE" =~ ^darwin ]] || return 1
}
is_ubuntu() {
  [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]] || return 1
}

[[ is_osx ]] && source "$DOTFILES/osx.sh"
[[ is_ubuntu ]] && source "$DOTFILES/ubuntu.sh"

# add binaries into the path
export PATH="$DOTFILES/bin:$PATH"

# make splat smarter
shopt -s dotglob nullglob

# source all the things
cd "$DOTFILES/source" || { echo "$DOTFILES/source is not a directory" >&2; return 2; }
for f in *; do
  source "$f"
done

# make sure links exist
cd "$DOTFILES/link" || { echo "$DOTFILES/link is not a directory" >&2; return 3; }
for f in *; do
  ln -fs "$DOTFILES/link/$f" "$HOME/$f"
done

# make sure files have been copied, but only if they don't exists already
cd "$DOTFILES/copy" || { echo "$DOTFILES/copy is not a directory" >&2; return 4; }
for f in *; do
  [ -e "$HOME/$f" ] || cp -r "$f" "$HOME/$f"
done

