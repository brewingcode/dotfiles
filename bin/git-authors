#!/usr/bin/env coffee

{ spawnSync } = require 'child_process'
_ = require 'lodash'

args = process.argv.slice(2)
squash = _.remove args, (x) -> x.match /^(-s|--squash-email)$/i
help = _.remove args, (x) -> x.match /^(-h|--help)$/i

if help.length
  console.log """
    usage: git-authors [-s|--squash-email] [args to git-log]

    Produces a sorted list of number of commits from emails in git-log. Use -s
    to squash emails into just user aliases, stripped of punctuation, eg:

        bettysue@yahoo.com ->  bettysue
        betty.sue@gmail.com -> bettysue

    The two emails above would then be counted as the same author.
  """
  process.exit()

git = spawnSync 'git', ['log', '--pretty=format:%ae', args...]

if git.status isnt 0
  console.error "git error (#{git.status}):", git.stderr.toString()
  process.exit(git.status)

counts = _(git.stdout.toString().split("\n"))
  .map (x) ->
    if squash.length
      x = x.replace(/@.*$/, '').replace(/\W/g, '')
    x.toLowerCase()
  .countBy()
  .map (v, k) -> [ k, v ]
  .sortBy (x) -> -x[1]
  .value()

total = _.sumBy counts, (x) -> x[1]

_.each counts, (x) ->
  percentage = _.round(x[1] / total * 100, 2).toFixed(2)
  console.log [ x[1], percentage, x[0] ].join("\t")
