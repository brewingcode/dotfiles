# Dotfiles

My OSX / Ubuntu / WSL dotfiles.

## How to use

Clone this repo somewhere (eg `~/.dotfiles`) and then source `init.sh`.

    source ~/.dotfiles/init.sh

## `lib` usage

This is a lib for multiple purposes:

1. Javascript packages `cd lib && yarn` and the `NODE_PATH` env var.

2. Python packages via `cd lib && pip install -r requirements.txt` and PYTHONPATH` env
   var. Note: venv interop is still TBD.

3. Coffeescripts that are built once to javascript to avoid the coffeescript
   runtime penalty. `cd lib && ./build-bins`, or use `yarn build` and `yarn dev`.
