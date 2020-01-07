#!/usr/bin/env coffee

###
This script is a shortcut to generate and open google searches without the
following annoyances:

- limiting to recent results with four clicks and one page load
- limiting to custom time range WITH A FUCKING CALENDAR WIDGET
- setting verbatim mode takes two clicks and page load
###

moment = require('moment-timezone')
child = require('child_process')

boolean = [ 'help', 'verbatim', 'paste' ]
alias = { w:'within' }
boolean.forEach (b) -> alias[b[0]] = b
args = require('minimist')(process.argv.slice(2), { boolean, alias })

if args.verbatim and args.within
  console.error('--verbatim and --within are mutually exclusive (google says so)')
  process.exit(1)

if args.help
  console.log '''
    usage: g <query> [short or long options]

    --within DURATION
        Limit to custom date range, such as:
            1y: 1 year
            6m: 6 months
            2w: 2 weeks
            3d: 3 days
            hour: last hour
            day: last day

    --verbatim
      Enable verbatim results (no personalization, literal search, etc)

    --paste
      Use contents of clipboard as search query
  '''
  process.exit(0)

query = null
if args.paste and args._.length
  console.error('search query cannot be mixed with --paste')
  process.exit(1)
else if args.paste
  query = child.execSync('pbpaste')
else if args._.length
  query = args._.join(' ')
else
  console.error('no search query specified')
  process.exit(1)

url = new URL('https://www.google.com/search')
url.searchParams.set('q', query)
url.searchParams.set('oq', query)

if args.within
  if m = args.within?.match?(/// ^ (\d+) ([ymwd]) $ ///)
    [ num, unit ] = m.slice(1)
    unit = 'M' if unit is 'm' # moment uses "m" for minutes, we want it for months
    t = moment.utc().subtract(+num, unit).tz('America/Los_Angeles').format('M/D/YYYY')
    url.searchParams.set('tbs', "cdr:1,cd_min:#{t}")
  else if args.within is 'hour'
    url.searchParams.set('tbs', 'qdr:h')
  else if args.within is 'day'
    url.searchParams.set('tbs', 'qdr:d')
  else
    console.error('invalid --within, see --help')
    process.exit(1)

if args.verbatim
  url.searchParams.set('tbs', 'li:1')
  url.searchParams.set('pws', '1')

console.log(url.toString())
child.spawn('open', [ url.toString() ], {stdio:'inherit'})
