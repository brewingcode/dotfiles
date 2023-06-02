require "#{process.env.DOTFILES}/lib/node-globals"

db = null

trace = -> 0 # console.warn

init = ->
    db = sqliteFile "#{process.env.DATA_ROOT}/cache.sqlite"

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
    return if row then row.val else undefined

if module.parent
    module.exports = { get, set }
else
    pr.try ->
        [fn, args...] = process.argv.slice(2)
        if fn is 'get'
            val = await get args[0]
            if _.isUndefined(val)
                console.warn "no value found for key: #{args[0]}"
                process.exit 1
            else
                console.log val
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
