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
