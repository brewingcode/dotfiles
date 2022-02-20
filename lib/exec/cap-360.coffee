# prints a JSON string of your account at Capital One 360
#   $ CAPITAL_CREDS=,username,password ./cap-360
#   {"customerReferenceId:"b933YCI3DPHkKB54ozkcoA==","accountDetails:{"subCat...

pup = require 'pup'
pr = require 'bluebird'
fs = require 'fs'

pr.try ->
  [user, pass] = process.env.CAPITAL_CREDS.match(/^(.)([^\1]+)\1(.*)/).slice(2)

  argv = pup.parse_args()
  argv.f = ['(myaccounts|verified).capitalone.com', 'i']
  [ browser, page ] = await pup.page(argv)
    headless: not debug
    defaultViewport:
      width: 600
      height: 2000
    devtools: debug

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
