
# Git shortcuts

alias g='git'
function ga() { git add "${@:-.}"; } # Add all files by default
alias gp='git push'
alias gpa='gp --all'
alias gu='git pull'
alias gl='git log'
alias gg='gl --decorate --oneline --graph --date-order --all'
alias gs='git status'
alias gst='gs'
alias gd='git diff'
alias gdc='gd --cached'
alias gm='git commit -m'
alias gma='git commit -am'
alias gb='git branch'
alias gba='git branch -a'
function gc() { git checkout "${@:-master}"; } # Checkout master by default
alias gco='gc'
alias gcb='gc -b'
alias gbc='gc -b' # Dyslexia
alias gr='git remote'
alias grv='gr -v'
#alias gra='git remote add'
alias grr='git remote rm'
alias gcl='git clone'
alias gcd='git rev-parse 2>/dev/null && cd "./$(git rev-parse --show-cdup)"'

# Current branch or SHA if detached.
alias gbs='git branch | perl -ne '"'"'/^\* (?:\(detached from (.*)\)|(.*))/ && print "$1$2"'"'"''

# Run commands in each subdirectory.
alias gu-all='eachdir git pull'
alias gp-all='eachdir git push'
alias gs-all='eachdir git status'

alias gitup='git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)"'

alias gitrc='git rebase --continue'
alias gitra='git rebase --abort'

function gitre() { git rebase -i "$(git merge-base HEAD "${1:-master}")"; }
function gitfp() { git commit --fixup HEAD "$@"; gitre HEAD^^; }

# open all changed files (that still actually exist) in the editor
function ged() {
  local files=()
  for f in $(git diff --name-only "$@"); do
    [[ -e "$f" ]] && files=("${files[@]}" "$f")
  done
  local n=${#files[@]}
  echo "Opening $n $([[ "$@" ]] || echo "modified ")file$([[ $n != 1 ]] && \
    echo s)${@:+ modified in }$@"
  q "${files[@]}"
}

# add a github remote by github username
function gra() {
  if (( "${#@}" != 1 )); then
    echo "Usage: gra githubuser"
    return 1;
  fi
  local repo=$(gr show -n origin | perl -ne '/Fetch URL: .*github\.com[:\/].*\/(.*)/ && print $1')
  gr add "$1" "git://github.com/$1/$repo"
}

# GitHub URL for current repo.
function gurl() {
  local remotename="${@:-origin}"
  local remote="$(git remote -v | awk '/^'"$remotename"'.*\(push\)$/ {print $2}')"
  [[ "$remote" ]] || return
  local user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
  echo "https://github.com/$user_repo"
}
# GitHub URL for current repo, including current branch + path.
alias gurlp='echo $(gurl)/tree/$(gbs)/$(git rev-parse --show-prefix)'

# git log with per-commit cmd-clickable GitHub URLs (iTerm)
function gf() {
  git log $* --name-status --color | awk "$(cat <<AWK
    /^.*commit [0-9a-f]{40}/ {sha=substr(\$2,1,7)}
    /^[MA]\t/ {printf "%s\t$(gurl)/blob/%s/%s\n", \$1, sha, \$2; next}
    /.*/ {print \$0}
AWK
  )" | less -F
}

# open last commit in GitHub, in the browser.
function gfu() {
  local n="${@:-1}"
  n=$((n-1))
  git web--browse  $(git log -n 1 --skip=$n --pretty=oneline | awk "{printf \"$(gurl)/commit/%s\", substr(\$1,1,7)}")
}
# open current branch + path in GitHub, in the browser.
alias gpu='git web--browse $(gurlp)'

# Just the last few commits, please!
for n in {1..5}; do alias gf$n="gf -n $n"; done

function gj() { git-jump "${@:-next}"; }
alias gj-='gj prev'

# OSX-specific Git shortcuts
if is_osx; then
  alias gdk='git ksdiff'
  alias gdkc='gdk --cached'
  function gt() {
    local path repo
    {
      pushd "${1:-$PWD}"
      path="$PWD"
      repo="$(git rev-parse --show-toplevel)"
      popd
    } >/dev/null 2>&1
    if [[ -e "$repo" ]]; then
      echo "Opening git repo $repo."
      gittower "$repo"
    else
      echo "Error: $path is not a git repo."
    fi
  }
fi

# print a nice view of all branch tips
#   githeads [remote_name]
# remote_name can be the bit after "refs/remotes/", or "." for the local repo, or
# blank to show all remotes plus the local repo
function githeads {
  if [[ "$1" == "" ]]; then
    git remote | while read -r remote; do
      githeads "$remote"
    done
    githeads "."
  else
    if [[ "$1" == "." ]]; then
      refspec=refs/heads
    else
      refspec=refs/remotes/$1
    fi

    echo "refspec: $refspec"
    git for-each-ref --sort=-committerdate \
      --format='%(committerdate)%09%(refname)%09%(objectname:short)%09%(committername)%09%(contents:subject)' \
      "$refspec" | perl -pe 's,refs/\S+/(\S+)\t,$1\t,' | gridify -t 50
  fi
}

# given the name of a git remote, fetch it and look for A..B rev ranges
# in the output so that we can print them nicely. If no remote is given,
# call `git remote` and run against each one.
function gitsync {
  if [[ "$1" == "" ]]; then
    git remote | while read -r remote; do
      echo "fetching $remote"
      gitsync "$remote"
    done
    git status
  else
    git fetch -p $1 2>&1 \
      | perl -ne '
        next unless /\S/;
        print "###\n### $_###\n";
        if (/^\s+(\w{7}\.\.\w{7})\s/) {
          print "\n";
          $fmt = q/'\''%C(yellow)%h %Cred%ai%Creset %s%Cgreen%d%Creset --%Cblue%an %Creset%n%b'\''/;
          $log = `git log --graph --pretty=format:$fmt $1 2>&1`;
          $log =~ s/\s*$//s;
          print "$log\n\n" unless $log =~ /fatal: ambiguous argument/;
          print `git diff --stat $1`, "\n";
        }'
  fi
}

# summary of local branches
function gitsumm {
  git branch | perl -lpe 's/[\s\*]//g' | sort | while read -r x; do
    git log --pretty=format:'%C(yellow)%h %Cred%ai%Creset %s%Cgreen%d%Creset --%C(cyan)%an %Creset' "$x" | head -7
    echo
  done
}

source $DOTFILES/vendor/git-completion.bash
