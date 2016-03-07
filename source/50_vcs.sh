
# Git shortcuts
alias gcd='git rev-parse 2>/dev/null && cd "./$(git rev-parse --show-cdup)"'

# Current branch or SHA if detached.
alias gbs='git branch | perl -ne '"'"'/^\* (?:\(detached from (.*)\)|(.*))/ && print "$1$2"'"'"''

alias gup='git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)"'
alias grc='git rebase --continue'
alias gra='git rebase --abort'

gitre() { git rebase -i "$(git merge-base HEAD "${1:-master}")"; }
gitfp() { git commit --fixup HEAD "$@"; gitre HEAD^^; }

# open all changed files (that still actually exist) in the editor
ged() {
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
gra() {
  if (( "${#@}" != 1 )); then
    echo "Usage: gra githubuser"
    return 1;
  fi
  local repo=$(gr show -n origin | perl -ne '/Fetch URL: .*github\.com[:\/].*\/(.*)/ && print $1')
  gr add "$1" "git://github.com/$1/$repo"
}

# GitHub URL for current repo.
gurl() {
  local remotename="${@:-origin}"
  local remote="$(git remote -v | awk '/^'"$remotename"'.*\(push\)$/ {print $2}')"
  [[ "$remote" ]] || return
  local user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
  echo "https://github.com/$user_repo"
}
# GitHub URL for current repo, including current branch + path.
alias gurlp='echo $(gurl)/tree/$(gbs)/$(git rev-parse --show-prefix)'

# OSX-specific Git shortcuts
if is_osx; then
  alias gdk='git ksdiff'
  alias gdkc='gdk --cached'
  gt() {
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
githeads() {
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
gitsync() {
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
gitsumm() {
  for i in remotes heads; do
    git for-each-ref --sort=committerdate refs/$i \
      --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' \
      | tail
  done
}

# checkout master, pull it, and switch back
gitmast() {
  head="$(git rev-parse --abbrev-ref HEAD)"
  gitsync
  git checkout master && git pull && git checkout "$head"
}

# no whitespace
gitnw() {
  git diff -b --numstat \
    | egrep $'^0\t0\t' \
    | cut -d$'\t' -f3- \
    | xargs git checkout HEAD --
}

source $DOTFILES/vendor/git-completion.bash
