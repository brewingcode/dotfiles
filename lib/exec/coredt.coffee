# coredt - Coredata Date Time conversion

readline = require 'readline'

convert = (s) ->
    # unix epoch time is 978307200 seconds before Coredata Date Time
    # https://www.epochconverter.com/coredata
    epoch = 978307200 + +s
    console.log new Date(epoch * 1000).toISOString()
  
convert(arg) for arg in process.argv.slice(2)

if not process.stdin.isTTY
    rl = readline.createInterface input: process.stdin
    rl.on 'line', convert
