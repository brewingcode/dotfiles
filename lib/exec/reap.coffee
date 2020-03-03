#!/usr/bin/env coffee

# Print process groups containing COMMAND that are older than AGE.
# Pass --kill to kill them off, too.

{ execSync, spawnSync } = require 'child_process'
moment = require 'moment'
minimist = require 'minimist'

argv = minimist process.argv.slice(2),
  boolean: ['kill', 'h', 'help']

if argv.h or argv.help
  console.log """
usage: reap COMMAND AGE [--kill]

Looks through the output of `ps wxo pid,pgid,etime,comm` to find processes
that match COMMAND and are older than AGE, where AGE is a moment.duration()
string such as "1d" for a day, or "4w" for four weeks. These processes are
then aggregated into their process group for summary execution.

Pass --kill to have this script run the process group kill command for you.
"""
  process.exit(0)

[ command, age ] = argv._
unless command and age
  console.error 'both command and age are required'
  process.exit(1)

textToDuration = (text) ->
  m = text.match(/^(\d+)([a-z])/i)
  moment.duration(+m[1], m[2]).as('seconds')

elapsedToSeconds = (text) ->
  m = text.match ///^
    ( ( \d+ )  -)?
    ( ( \d+ )  :)?
    ( \d+ )
    :
    ( \d+ )
  $///
  (+m[2] or 0) * 86400 + (+m[4] or 0) * 3600 + (+m[5] or 0) * 60 + (+m[6] or 0)

pgids = {}

execSync('ps wxo pid,pgid,etime,comm').toString().split(/\n/).map (line) ->
  line.match(/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(.*)/)
.filter (m) ->
  m
.forEach ([_, pid, pgid, etime, comm]) ->
  return if comm isnt command
  return if elapsedToSeconds(etime) < textToDuration(age)
  pgids[pgid] = [] unless pgids[pgid]
  pgids[pgid].push(pid)

if Object.keys(pgids).length
  console.log "PGID\tPID(s)"
  for pgid, pids of pgids
    console.log pgid, "\t", pids.join(' ')
    if argv.kill
      spawnSync '/bin/kill', ['TERM', '-'+pgid]
