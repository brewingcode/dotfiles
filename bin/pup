#!/usr/bin/env coffee

puppeteer = require 'puppeteer'
argv = require('minimist') process.argv.slice(2)

usage = """
usage: pup URL [-d URLDATA] [-H HEADER ...]

Prints the final DOM of a page after a full navigation. Default HTTP method is
a GET, use `-d URLDATA` to do a POST with URLDATA instead. Use -H to send 
additional HTTP request headers.
"""

if argv.h or argv.help
  console.log usage
  process.exit()

[ url ] = argv._
if not url
  console.error "error: no url given"
  process.exit 1

debug = false

do ->
  try
    browser = await puppeteer.launch
      headless: not debug
      defaultViewport:
        width: 600
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

    await page.goto url
    console.log await page.content()
    await browser.close()
  catch e
    console.error e.message
    process.exit(2)
