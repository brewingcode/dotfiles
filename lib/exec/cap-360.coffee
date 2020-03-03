# prints a JSON string of your account at Capital One 360
#   $ CAPITAL_CREDS=,username,password ./cap-360
#   {"customerReferenceId:"b933YCI3DPHkKB54ozkcoA==","accountDetails:{"subCat...

puppeteer = require 'puppeteer'
pr = require 'bluebird'
fs = require 'fs'
debug = false

pr.try ->
  [user, pass] = process.env.CAPITAL_CREDS.match(/^(.)([^\1]+)\1(.*)/).slice(2)

  browser = await puppeteer.launch
    headless: not debug
    defaultViewport:
      width: 600
      height: 2000
    devtools: debug

  page = (await browser.pages())[0]
  await page.setUserAgent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'
  await page.evaluateOnNewDocument ->
    Object.defineProperty navigator, i[0], i[1] for i in [
      [ 'languages', [ 'en-US', 'en', 'mt' ] ]
      [ 'plugins', [ 1, 2, 3 ] ]
      [ 'webdriver', false ]
    ]

  await page.setRequestInterception true
  page.on 'request', (req) ->
    { host } = new URL req.url()
    console.warn host if debug
    if host.match /(myaccounts|verified).capitalone.com/i
      req.continue()
    else
      req.abort()

  waitClick = (sel) ->
    try
      await page.waitForSelector sel
      await page.waitFor 500
      await page.click sel
    catch
      file = '/tmp/cap-360-error'
      fs.writeFileSync "#{file}.png", await page.screenshot()
      fs.writeFileSync "#{file}.html", await page.evaluate -> document.body.innerHTML
      throw new Error "failed to waitClick #{sel}, see #{file}.{html,png}"

  await page.goto 'https://verified.capitalone.com/auth/signin'
  await page.type 'input[data-controlname=username]', user
  await page.type 'input[data-controlname=password]', pass
  await page.click 'button.sign-in-button'
  await waitClick 'button.atddAccountSummaryTileButton'
  [xhr] = await pr.all [
    page.waitForResponse (res) -> res.url().match /getaccountbyid/
    waitClick '#viewDetailLink'
  ]
  console.log await xhr.text()
  await browser.close()
.catch (e) ->
  console.error e.stack
  process.exit(1) unless debug
