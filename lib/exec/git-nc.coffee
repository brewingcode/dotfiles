require "#{process.env.DOTFILES}/lib/node-globals"
{ execAsync } = pr.promisifyAll require 'child_process'

remote = ''
branches = {}
commits = {}

if process.env.RELEASE_BRANCHES
    release_branches = new RegExp process.env.RELEASE_BRANCHES, 'i'

lines = (cmd) ->
    out =  await execAsync cmd, maxBuffer:10_000_000
    return out
        .split('\n')
        .filter (line) -> line.match /\S/
        .map (line) -> line.trim()

newBranch = (branch) ->
    # for a new branch, we walk the commits and consider each one as a new one, until we find a commit that either:
    #   * exists in a "release branch" if that env var is set
    #   * exists in more than one branch otherwise
    for commit in await lines "git log --pretty='%h,%ai' '#{branch}'"
        [sha, date] = commit.split(',')
        contains = await lines "git branch -a --contains #{sha} | perl -pe s,^remotes/,,"
        branches[branch].push { sha, date, in:contains }
        commits[sha] = {sha, date, newIn:[], in:contains } unless commits[sha]
        commits[sha].newIn.push branch
        if release_branches and contains.find (b) -> b.match release_branches
            return
        else
            return if contains.length > 1

existingBranch = (branch, ref) ->
    [ start, end ] = ref.match /(\S+)\.\.(\S+)/
    for commit in await lines "git log --pretty='%h,%ai' '#{ref}'"
        [sha, date] = commit.split(',')
        contains = await lines "git branch -a --contains #{sha} | perl -pe s,^remotes/,,"
        branches[branch].push { sha, date, in:contains }
        commits[sha] = {sha, date, newIn:[], in:contains } unless commits[sha]
        commits[sha].newIn.push branch

main = ->
    for line in await lines 'cat /tmp/fetch.txt'
        if m = line.match /^From (\S+)/
            remote = m[1]
        else if m = line.match /// (\S+) \s+ \S+ \s+ -> \s+ (\S+) ///
            [ range, branch ] = m.slice(1)
            branches[branch] = []
            if range is 'branch]'
                await newBranch(branch)
            else
                await existingBranch(branch, range)

    display = {}
    await pr.each _.keys(branches), (b) ->
        display[b] = ''
        await pr.each branches[b], (c) ->
            display[b] += await execAsync "git plog -1 #{c.sha}"
            display[b] += "\n"

    _(branches)
        .keys()
        .sortBy (n) -> branches[n][0].date
        .reverse()
        .each (b) -> console.log "#\n# #{b}\n#\n#{display[b]}"

pr.try main