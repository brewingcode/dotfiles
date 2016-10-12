[ -d "$DOTFILES" ] || echo { \$DOTFILES does not point to a directory >&2; return 1; }

# OS detection
is_osx() {
  [[ "$OSTYPE" =~ ^darwin ]] || return 1
}
is_ubuntu() {
  [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]] || return 1
}
get_os() {
  for os in osx ubuntu; do
    is_$os; [[ $? == ${1:-0} ]] && echo $os
  done
}

# add binaries into the path
export PATH="$DOTFILES/bin:$PATH"

# source all the things
cd "$DOTFILES"/source
for f in *; do
  source "$f"
done

# make sure links exist
cd "$DOTFILES"/links
for f in *; do
  ln -fs "$DOTFILES/links/$f" "$HOME/$f"
done

# make sure files have been copied, but only if they don't exists already
cd "$DOTFILES/copy"
for f in *; do
  [ -e "$HOME/$f" ] || cp -r "$f" "$HOME"
done

