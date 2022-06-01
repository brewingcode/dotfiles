#!/usr/bin/env coffee

csv = require 'csv-parse/sync'
fs = require 'fs'
console.log JSON.stringify csv.parse fs.readFileSync('/dev/stdin', 'utf-8'),
    # https://csv.js.org/parse/options/
    relax_column_count: true
