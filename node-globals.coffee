fs = require 'fs'

die = (args...) ->
    console.error args...
    process.exit 1

for x in ['www', 'data']
    key = "#{x}_root".toUpperCase()
    unless val = process.env[key]
        die "#{key} env var is not defined"

    unless fs.existsSync val
        die "#{key}=#{val} path does not exist"

    global[key.toLowerCase()] = val

global.die = die

global.fs = fs
global.moment = require 'moment'
global.pr = require 'bluebird'
global._ = require 'lodash'
global.rp = require 'request-promise'