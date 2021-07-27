puppeteer = require 'puppeteer'
pr = require 'bluebird'

usage = """
usage: pup [-d URLDATA] [-H HEADER ...] URL [more urls...]

Prints the final DOM of a page after a full navigation. Default HTTP method is
a GET, use `-d URLDATA` to do a POST with URLDATA instead. Use -H to send
additional HTTP request headers.
"""

debug = false

get = (argv) ->
  try
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
        console.log "setting #{req.url()} to POST"
        req.continue
          method: 'POST'
          postData: argv.d
          headers: {
            ...req.headers()
            ...headers
            ...(if argv.d then 'Content-type': 'application/x-www-form-urlencoded' else null)
          }

    await page.setUserAgent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'
    await page.evaluateOnNewDocument ->
      Object.defineProperty navigator, i[0], i[1] for i in [
        [ 'languages', [ 'en-US', 'en', 'mt' ] ]
        [ 'plugins', [ 1, 2, 3 ] ]
        [ 'webdriver', false ]
      ]

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

unless module.parent
  do ->
    argv = require('minimist') process.argv.slice(2),
      boolean: ['ignore-nav-fail']

    if argv.h or argv.help
      console.log usage
      process.exit()

    if not argv._.length
      console.error "error: no urls given"
      process.exit 1

    console.log (await get(argv)).join('\n')

module.exports = { get }