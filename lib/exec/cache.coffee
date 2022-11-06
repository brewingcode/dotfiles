sqlite = require 'sqlite3'
pr = require 'bluebird'
fs = require 'fs'

db = null

trace = -> 0 # console.warn

init = ->
    db = pr.promisifyAll new sqlite.Database "#{process.env.DATA_ROOT}/cache.sqlite"

    # sqlite3 does run() in a very weird way
    db.runAsync = (sql, params) ->
        new pr (resolve, reject) ->
            db.run sql, params, (err) ->
                return reject(err) if err
                resolve(this) # this is the weird thing: `this` is what should be returned

    await db.runAsync """create table if not exists cache(
        key text primary key not null,
        val text,
        ttl integer default 0
    )"""

set = (key, val, ttl) ->
    await init()
    trace 'set:', key, val, (new Date() / 1000), ttl
    if ttl > 0
        ttl += new Date() / 1000
    else
        ttl = 0
    await db.runAsync 'insert or replace into cache
        values (?,?,?)', [key, val, ttl]

get = (key) ->
    await init()
    now = new Date() / 1000
    trace 'get:', key, now
    row = await db.getAsync '
        select * from cache
        where key = ? and
            ( ttl = 0 or ? < ttl )
        ', [key, now]
    return row.val if row
    throw Error "no cache entry for #{key}"

if module.parent
    module.exports = { get, set }
else
    pr.try ->
        [fn, args...] = process.argv.slice(2)
        if fn is 'get'
            console.log await get args[0]
        else if fn is 'set'
            [ key, val, ttl ] = args
            val = fs.readFileSync(0) if val is '-'
            ttl = if ttl then parseInt(ttl) else 0
            await set key, val, ttl
        else
            throw Error 'unrecognized function: #{fn}'
    .catch (e) ->
        console.error e
        process.exit 1
