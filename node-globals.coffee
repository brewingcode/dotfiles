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
