#!/bin/bash

echo "https://rvm.io/rvm/install"

echo "running sudo to verify you can do the root-level rvm install steps (autolibs)"
sudo true
[ $? -eq 0 ] || { echo "nope, sorry skipping rvm after all" >&2; exit 1; }

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --ruby
