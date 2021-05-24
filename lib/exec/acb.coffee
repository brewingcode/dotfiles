# Output the last last N entries from the Alfred Clipboard. Default is 1,
# equivalent to a simple `pbpaste`. With arguments, output more entries, or
# even selectively zero out entries.

sqlite3 = require('sqlite3')
argv = require('minimist') process.argv.slice(2),
  boolean: ['h', 'help', 's', 'short', 'e', 'erase']

usage = ->
    console.log """
usage: acb [LIMIT]
       acb [--limit LIMIT] [--offset OFFSET] [--from FROM] [--short] [--erase]
       acb [-l LIMIT] [-o OFFSET] [-f FROM] [-s] [-e]

Prints the most recent LIMIT (default 1) and OFFSET (default 0)
items from Alfred's Clipboard database.  --short will output shortened items
by stripping newlines and only including the first 70 characters. FROM is
available as a variant of OFFSET: it is simply OFFSET + 1. For example:

    acb -l 4 -o 4    # output items ⌘5 through ⌘8 (0-based counting)
    acb -l 4 -f 5    # the same thing (1-based counting, like the UI)

You can also erase the specified entry(s) with --erase.

Note that binary items will have their size printed.
"""

if argv.help or argv.h
    usage()
    process.exit()

limit = argv.limit or argv.l or 1
offset = argv.offset or argv.o or 0
if from = argv.from or argv.f
    offset = from - 1
if argv._
    limit = argv._[0]

db = new sqlite3.Database("#{process.env.HOME}/Library/Application Support/Alfred 3/Databases/clipboard.alfdb")

if argv.erase or argv.e
    db.run "update clipboard set item = '' order by ts desc limit #{limit} offset #{offset}"
else
    if argv.short or argv.s
        # first 70 chars, minus newlines
        col="substr(replace(item, char(10), ' '), 0, 70) as item"
    else
        col="item"

    db.each "select #{col} from clipboard where dataHash is null order by ts desc limit #{limit} offset #{offset}", (err, row) ->
        console.log row.item
