# run job

fs = require 'fs'
argv = require('minimist') process.argv.slice(2),
    boolean: ['h', 'help', 'd', 'detached']
sqlite = require 'sqlite-async'
child = require 'child_process'

data_dir = process.env.HOME + '/.rj'

if argv.help or argv.h
    console.log """
USAGE
    rj [-d] -- CMD [ARG ...]
    rj [-t] ACTION ROWID

With CMD, run a command via queue, and wait for it to finish. Prints the ROWID
of the job.

With ACTION, perform operations on the queue.

OPTIONS
-d/--detached      detach job from rj process
-t/--tail          tail -f instead of print with -o/-e

ACTIONS
-k/--kill ROWID    kill ROWID
-o/--out ROWID     print stdout of ROWID to stdout
-e/--err ROWID     print stderr of ROWID to stderr
    """
    process.exit()

sql = (fn) ->
    db = await sqlite.open "#{data_dir}/db.sqlite"
    await db.run """
        create table if not exists jobs (
            id integer primary key,
            cmd text not null,
            created datetime not null default (strftime('%Y-%m-%d %H:%M:%f', 'now')),
            started datetime,
            ended datetime,
            retry integer default 0,
            pid integer,
            status integer)"""
    await fn(db)

run = (rowID) ->
    job_dir = data_dir + "/#{rowID}"
    fs.mkdirSync(job_dir) if not fs.existsSync(job_dir)
    row = await sql (db) -> db.get "select * from jobs where id = ?", [rowID]
    cmd = JSON.parse(row.cmd)

    await sql (db) -> db.run "update jobs set started = strftime('%Y-%m-%d %H:%M:%f', 'now') where id = ?", [rowID]
    proc = child.spawn cmd[0], cmd.slice(1),
        stdio: ['ignore', fs.openSync(job_dir+'/out.txt', 'w'), fs.openSync(job_dir+'/err.txt', 'w')]
    proc.on 'error', console.error
    await new Promise (res) ->
        proc.on 'exit', res
        proc.on 'close', res

    await sql (db) -> db.run "update jobs set status = ?, ended = strftime('%Y-%m-%d %H:%M:%f', 'now') where id = ?", [proc.exitCode, rowID]
    return proc.exitCode

fork = ->
    { lastID } = await sql (db) -> db.run "insert into jobs(cmd) values(?)", [JSON.stringify(argv._)]
    console.log lastID
    detached = argv.d or argv.detached
    proc = child.fork __filename, ['-c', lastID, if detached then '-d' else ''],
        stdio: 'inherit'
        detached: detached

    await sql (db) -> db.run "update jobs set pid = ? where id = ?", [proc.pid, lastID]

    if detached
        proc.unref()
        proc.disconnect()
    else
        process.on 'SIGINT', -> proc.kill()
        await new Promise (res) -> proc.on 'exit', res
        return proc.exitCode

kill = (rowID) ->
    row = await sql (db) -> db.get "select * from jobs where id = ?", [rowID]
    child.execSync "kill -INT -#{row.pid}"

print = (rowID, which) ->
    row = await sql (db) -> db.get "select * from jobs where id = ?", [rowID]
    path = data_dir + "/#{rowID}/#{which}.txt"
    if argv.t or argv.tail
        child.spawn 'tail', ['-f', path]
    else
        data = fs.readFileSync(path).toString()
        if which is 'out'
            console.log(data)
        else
            console.error(data)

main = ->
    if c = argv.c or argv.child
        await run(c)
    else if k = argv.k or argv.kill
        await kill(k)
    else if o = argv.o or argv.out
        await print(o, 'out')
    else if e = argv.e or argv.err
        await print(e, 'err')
    else
        if argv._.length is 0
            process.stderr.write("error: command required, see --help\n")
            return 1
        fs.mkdirSync(data_dir) if not fs.existsSync(data_dir)
        await fork()

unless module.parent
    do -> process.exit await main()

module.exports = { main, sql, run }