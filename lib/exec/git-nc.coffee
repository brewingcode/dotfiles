require "#{process.env.DOTFILES}/lib/node-globals"
{ execAsync } = pr.promisifyAll require 'child_process'

remote = ''
branches = {}
commits = {}

if process.env.RELEASE_BRANCHES
    release_branches = new RegExp process.env.RELEASE_BRANCHES, 'i'

lines = (cmd) -> (await execAsync cmd)
    .split('\n') 
    .filter (line) -> line.match /\S/
    .map (line) -> line.trim()

walkBranch = (branch) ->
    # for a new branch, we walk the commits and consider each one as a new one, until we find a commit that either:
    #   * exists in a "release branch" if that env var is set
    #   * exists in more than one branch otherwise
    branches[branch] = []
    for line in await lines "git log --pretty='%h,%ae,%ai' '#{branch}'"
        [sha, author, date] = line.split(',')
        contains = await lines "git branch -a --contains #{sha}"
        branches[branch].push { sha, author, date, branches }
        if release_branches and contains.find (b) -> b.match release_branches
            return
        else
            return if contains.length > 1

commits = -> 0

main = ->
    for line in await lines 'cat /tmp/fetch.txt'
        if m = line.match /^From (\S+)/
            remote = m[1]
        else if m = line.match /// (\S+) \s+ \S+ \s+ -> \s+ (\S+) ///
            [ range, branch ] = m.slice(1)
            if range is 'branch]'
                await walkBranch(branch)
            else
                await commits(range)
    
    console.log branches

pr.try main