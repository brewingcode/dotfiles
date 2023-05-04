# name conflict with pup css-based html reader:

# https://news.ycombinator.com/item?id=33805732
# https://github.com/ericchiang/pup

require "#{process.env.DOTFILES}/lib/node-globals"
puppeteer = require 'puppeteer'
crypto = require 'crypto'
mkdirp = require 'mkdirp'
slugify = require 'slugify'

cache_path = process.env.PUP_CACHE
if not fs.existsSync cache_path
  console.error 'PUP_CACHE env var needs to be an existing file path'
  process.exit 1

usage = """
usage: pup [options] URL [more urls...]

Prints the final DOM of a page after a full navigation via Puppeteer.

OPTIONS

-d URLDATA  Change GET to POST, and send URLDATA
-H HEADER   Add HEADER (should be "name:value") to request
-c FILE     Set cookies from FILE, should be JSON array of objects
-f REGEX    Filter requests via host matching REGEX. Add another `-f FLAGS`
            to set regex flags like "i" for case-insensitive
-i          Ignore navigation failures, log anyway
-v          Verbose
-a NUM      Return cached content, unless it is older than NUM seconds. If
            NUM is zero or less, always return cached content

API

    pup = require 'pup'
    argv = pup.parse_args()
    [ browser, page ] = await pup.page(argv)
    console.log await page.evaluate 'document.documentElement.outerHTML'
    await browser.close()
"""

debug = false

cachepath = (url) ->
  h = crypto.createHash('sha1')
  h.update(url)
  sha1 = h.digest('hex')
  dir = cache_path + '/' + sha1.match(/\w{5}/g).join('/')
  mkdirp.sync(dir)
  "#{dir}/#{slugify(url)}".match(/^(.{0,250})/)[1]

# returns content of a url if it is less than age seconds old
getcache = (url, age) ->
  file = cachepath(url)
  console.warn "cachepath: #{file}" if debug
  if fs.existsSync(file)
    mtime = moment(fs.statSync(file).mtime)
    dur = mtime.diff(moment())
    if age <= 0 or Math.abs(dur/1000) < age
      content = fs.readFileSync(file) or ''
      age_ago = moment.duration(dur).humanize(true)
      console.warn "cache hit: #{content.length} bytes from #{age_ago}" if debug
  if not content and debug
    console.warn "cache miss" if debug
  return content

setcache = (url, content) ->
  file = cachepath(url)
  fs.writeFileSync(file, content)
  return file

log = (x...) -> console.warn(new Date(), x...) if debug

_page = (argv) ->
  browser = await puppeteer.launch
    headless: not debug
    defaultViewport:
      width: 1200
      height: 2000
    devtools: debug

  page = (await browser.pages())[0]
  headers = null
  if argv.H
    headers = {}
    for h in (if typeof argv.H is 'string' then [argv.H] else argv.H)
      [k,v] = h.match(/^([^:]+):\s*(.*)/).slice(1)
      headers[k] = v

  if argv.d or headers
    await page.setRequestInterception(true)
    page.once 'request', (req) ->
      log "setting #{req.url()} to POST"
      req.continue
        method: 'POST'
        postData: argv.d
        headers: {
          ...req.headers()
          ...headers
        }

  if argv.c
    cookies = JSON.parse fs.readFileSync(argv.c)
    await page.setCookie(...cookies)

  if argv.f
    await page.setRequestInterception(true)
    re = if typeof argv.f is 'string' then new RegExp(argv.f) else new RegExp(...argv.f)
    page.on 'request', (req) ->
      { host } = new URL req.url()
      if host.match re
        log 'yes:', host
        req.continue()
      else
        log 'no:', host
        req.abort()

  await page.setUserAgent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'
  await page.evaluateOnNewDocument ->
    Object.defineProperty navigator, i[0], i[1] for i in [
      [ 'languages', [ 'en-US', 'en', 'mt' ] ]
      [ 'plugins', [ 1, 2, 3 ] ]
      [ 'webdriver', false ]
    ]

  return [ browser, page ]

get = (argv) ->
  content = argv._.map -> null

  if argv.a?
    argv._.forEach (url, i) ->
      content[i] = getcache url, argv.a

  if content.filter(Boolean).length is content.length
    return content

  try
    [browser, page] = await _page(argv)
    await pr.each argv._, (url, i) ->
      return if content[i]
      console.warn ".goto(url)" if debug
      try
        await page.goto url, waitUntil:'networkidle0'
      catch e
        if not argv['ignore-nav-fail']
          throw e
      content[i] = await page.content()

      if argv.a?
        setcache(url, content[i])

    await browser.close()
    return content
  catch e
    console.error e.message
    process.exit(2)

parse_args = ->
  argv = require('minimist') process.argv.slice(2),
    boolean: ['i', 'v', 'ignore-nav-fail']
  debug = true if argv.v
  return argv

unless module.parent
  do ->
    argv = parse_args()
    if argv.h or argv.help
      console.log usage
      process.exit()

    if argv.v
      debug = true

    if not argv._.length
      console.error "error: no urls given"
      process.exit 1

    console.log (await get(argv)).join('\n')

module.exports = { page:_page, parse_args, get, log, getcache, setcache }
