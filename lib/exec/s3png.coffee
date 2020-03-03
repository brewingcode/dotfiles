pr = require 'bluebird'
request = require 'request-promise'
proc = pr.promisifyAll require 'child_process'
crypto = pr.promisifyAll require 'crypto'
fs = pr.promisifyAll require 'fs'
argv = require('minimist') process.argv.slice(2),
  boolean: ['h', 'help', 'v', 'verbose']
conf = require('rc') 's3png', {}, argv

{ log, error } = console

if argv.h or argv.help
  log """
usage: s3png [[-m|--message] TITLE]

  -m TITLE, --message=TITLE    Use TITLE instead of "image" for image title
  -h, --help                   This message
  -q, --quiet                  No output

Pull a .png off the pasteboard with the `pngpaste` command, upload it to an S3
bucket, and then copy a markdown link to the image back to the pasteboard. S3
credentials are passed via `rc`, or the S3PNG env var, which must be the
bucket name, access key, and secret key, all separated by colons.

    $ export S3PNG=examplebucket:AKIAIOSFODNN7EXAMPLE:wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    $ s3png && pbpaste
    ![image](https://examplebucket.s3.amazonaws.com/7dad6834e1fb6d7d922540cd1a228c42429cd2dd.png)
"""
  process.exit(0)

if not (conf.bucket and conf.accessKey and conf.secretKey)
  fmt = "<bucket>:<accessKey>:<secretKey>"
  if not env = process.env.S3PNG
    error "error: missing S3PNG env var, export one matching #{fmt} and try again"
    process.exit(1)
  parts = process.env.S3PNG.split(':')
  if parts.length isnt 3
    error "error: S3PNG must match format: #{fmt}"
    process.exit(2)
  [ bucket, accessKey, secretKey ] = parts
  conf = { ...conf, bucket, accessKey, secretKey }

log = ->
  unless conf.quiet
    console.log arguments...

main = ->
  await proc.execAsync("mkdir -p /tmp/s3png")
  rand = await crypto.randomBytesAsync(6).then (buf) -> buf.toString('hex')
  tmpfile = "/tmp/s3png/#{rand}.png"
  await proc.execAsync("pngpaste #{tmpfile}")

  log "pngpasted to #{tmpfile}: #{fs.statSync(tmpfile).size} bytes"
  sha1 = await fs.readFileAsync(tmpfile).then (buf) ->
    crypto.createHash('sha1').update(buf).digest('hex')
  pngfile = "/tmp/s3png/#{sha1}.png"
  await proc.execAsync("mv #{tmpfile} #{pngfile}")

  prs = await pr.all [
    upload(pngfile)
    #crush(pngfile, '50%', 'half').then (f) -> upload(f)
    #crush(pngfile, '25%', 'quarter').then (f) -> upload(f)
  ]

  title = argv.m or argv.message or "image"
  log "uploaded to #{prs[0]}"
  proc.execAsync("echo '![#{title}](#{prs[0]})' | pbcopy")

# TODO: this produces *terrible* images, find something better
crush = (pngfile, percentage, label) ->
  #log 'crush:', arguments
  newpng = pngfile.replace(/\.png$/, "-#{label}.png")
  await proc.execAsync("convert -resize '#{percentage}' #{pngfile} #{newpng}")
  return newpng

upload = (filename) ->
  #log 'upload:', arguments
  [ ..., justfile ] = filename.match(/([^\/]+)$/)
  host = "https://#{conf.bucket}.s3.amazonaws.com"
  date = new Date().toUTCString()
  auth = await crypto.createHmac('sha1', conf.secretKey)
    .update "PUT\n\nimage/png\n#{date}\n/#{conf.bucket}/#{justfile}"
    .digest('base64')

  await fs.readFileAsync(filename).then (buf) ->
    request
      method: 'PUT'
      uri: "#{host}/#{justfile}"
      body: await fs.readFileAsync(filename)
      headers:
        date: date
        authorization: "AWS #{conf.accessKey}:#{auth}"
        'content-type': 'image/png'

  return "#{host}/#{justfile}"

main().catch (err) -> error err.stack
