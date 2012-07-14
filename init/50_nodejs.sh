# Install latest Node.js with nave
e_header "Installing Node.js $(~/.dotfiles/bin/nave latest)"
~/.dotfiles/bin/nave install latest >/dev/null 2>&1

# Install Npm if necessary (the brew recipe doesn't do this).
if [[ "$(type -P node)" && ! "$(type -P npm)" ]]; then
  e_header "Installing Npm"
  curl http://npmjs.org/install.sh | sh
fi

# Install Npm modules.
if [[ "$(type -P npm)" ]]; then
  # Update Npm!
  npm update -g npm

  modules=(grunt jshint uglify-js codestream)

  { pushd "$(npm config get prefix)/lib/node_modules"; installed=(*); popd; } > /dev/null
  list="$(to_install "${modules[*]}" "${installed[*]}")"
  if [[ "$list" ]]; then
    e_header "Installing Npm modules: $list"
    npm install -g $list
  fi
fi
