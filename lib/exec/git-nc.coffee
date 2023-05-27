# git-nc: git new commits

require "#{process.env.DOTFILES}/lib/node-globals"
{ execAsync } = pr.promisifyAll require 'child_process'
chalk = require 'chalk'

remote = ''
branches = {}
commitCache = {}

if process.env.RELEASE_BRANCHES
    release_branches = new RegExp process.env.RELEASE_BRANCHES, 'i'

lines = (cmd) ->
    # run a command and return its stdout as chomp'd non-empty lines, OR just slurp stdin
    if cmd
        out =  await execAsync cmd, maxBuffer:10_000_000
    else
        out = fs.readFileSync(0).toString()

    return out
        .split('\n')
        .filter (line) -> line.match /\S/
        .map (line) -> line.trim()

commit = (sha) ->
    # get everything we need about a single sha
    if not commitCache[sha]
        contains = await lines "git branch -a --contains #{sha}"
        commitCache[sha] =
            contains: contains.map (x) -> x.replace /^remotes\//, ''
            display: await execAsync "git log --color=always --pretty=format:'%C(magenta)%h %Cred%ai%Creset %s --%C(cyan)%an %Creset' -1 #{sha}"
    return commitCache[sha].contains

newBranch = (branch) ->
    # for a new branch, we walk the commits and consider each one as a new one, until we find a commit that either:
    #   * exists in a "release branch" if that env var is set
    #   * exists in more than one branch otherwise
    commits = []
    for c in await lines "git log --pretty='%h,%ai' '#{branch}'"
        [sha, date] = c.split(',')
        contains = await commit(sha)
        commits.push { sha, date, in:contains, via:branch }
        if release_branches and contains.find (b) -> b.match release_branches
            break
        else
            break if contains.length > 1
    return { commits, new:true }

existingBranch = (branch, start, end) ->
    # existing branches are reported as a ref range, we want to ammend it slightly to get one earlier commit
    commits = []
    for c in await lines "git log --pretty='%h,%ai' '#{start}^..#{end}'"
        [sha, date] = c.split(',')
        contains = await commit(sha)
        commits.push { sha, date, in:contains, via:branch }
    return { commits, new:false }

gitFetch = ->
    if process.stdin.isTTY
        now = moment().toISOString()
        await lines "git fetch --all --tags 2>&1 | tee '/tmp/git-nc-#{now}'"
    else
        await lines()

pr.try ->
    for line in await gitFetch()
        if m = line.match /^From (\S+)/
            remote = m[1]
        else if m = line.match /// (\S+) \s+ \S+ \s+ -> \s+ (\S+) ///
            [ range, branch ] = m.slice(1)

            if range is 'branch]'
                branches[branch] = await newBranch(branch)
            else if m = range.match(/(\S+)\.\.(\S+)/)
                branches[branch] = await existingBranch(branch, m[1], m[2])
            else
                # garbage

    _(branches)
        .keys()
        .sortBy (n) -> branches[n].commits[0].date
        .each (n) ->
            b = branches[n]
            console.log if b.new then chalk.green(n) else chalk.yellow(n)
            for c in b.commits
                console.log commitCache[c.sha].display
