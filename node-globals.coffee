pr = require 'bluebird'
fs = pr.promisifyAll require 'fs'
global.fs = fs
global.pr = pr

die = (args...) ->
    console.error args...
    process.exit 1
global.die = die

for x in ['www', 'data']
    key = "#{x}_root".toUpperCase()
    unless val = process.env[key]
        die "#{key} env var is not defined"

    unless fs.existsSync val
        die "#{key}=#{val} path does not exist"

    global[key.toLowerCase()] = val

global.moment = require 'moment'
global._ = require 'lodash'
global.rp = require 'request-promise'

global.sqliteFile = (filename) ->
    obj = pr.promisifyAll new (require 'sqlite3').Database(filename or 'db.sqlite')

    # sqlite3 does run() in a very weird way
    obj.runAsync = (sql, params...) ->
        new pr (resolve, reject) ->
            obj.run sql, params, (err) ->
                return reject(err) if err
                resolve(this) # this is the weird thing: `this` is what should be returned

    return obj
