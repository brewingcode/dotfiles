puppeteer = require 'puppeteer'
pr = require 'bluebird'
fs = require 'fs'

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

API

    pup = require 'pup'
    argv = pup.parse_args()
    [ browser, page ] = await pup.page(argv)
    console.log await page.evaluate 'document.documentElement.outerHTML'
    await browser.close()
"""

debug = false

log = (x...) -> console.warn(new Date(), x...) if debug

page = (argv) ->
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
  try
    [browser, page] = await page(argv)
    content = []
    await pr.each argv._, (url) ->
      try
        await page.goto url, waitUntil:'networkidle0'
      catch e
        if not argv['ignore-nav-fail']
          throw e
      content.push await page.content()
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

module.exports = { page, parse_args, get, log }
