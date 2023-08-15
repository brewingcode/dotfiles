fs = require 'fs'
parse = require 'content-security-policy-parser'

console.log JSON.stringify parse fs.readFileSync('/dev/stdin').toString()
