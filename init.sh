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

