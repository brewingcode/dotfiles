[ -d "$DOTFILES" ] || echo { \$DOTFILES does not point to a directory >&2; return 1; }

# add binaries into the path
export PATH="$DOTFILES/bin:$PATH"

# pull in dotfiles utility functions
cd "$DOTFILES/utils.sh"

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

