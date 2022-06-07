# run job

fs = require 'fs'
argv = require('minimist') process.argv.slice(2),
    boolean: ['h', 'help', 'd', 'detached', 't', 'tail',
    'r', 'running']
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
-d/--detached      detach job from rj process and return immediately
-t/--tail          tail -f instead of print with -o/-e

ACTIONS
kill ROWID     sigkill ROWID
out  ROWID     print stdout of ROWID to stdout
err  ROWID     print stderr of ROWID to stderr
running        print jobs currently running
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
    await sql (db) -> db.run "update jobs set status = ?, ended = strftime('%Y-%m-%d %H:%M:%f', 'now') where id = ?", [proc.exitCode, rowID]

    await new Promise (res) ->
        proc.on 'exit', res
        proc.on 'close', res

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
        await new Promise (res) ->
            proc = child.spawn 'tail', ['-f', path], stdio: 'inherit'
            proc.on 'exit', res

    else
        data = fs.readFileSync(path).toString()
        if which is 'out'
            console.log(data)
        else
            console.error(data)

running = ->
    pids = {}
    proc = child.spawnSync('pgrep', ['-fl', '.'])
    proc.stdout.toString().split(/\n/).forEach (line) ->
        if m = line.match(/^(\d+)\s+/)
            pids[m[1]] = 1

    rows = await sql (db) -> db.all "select pid, id, cmd from jobs where pid  is not null"

    active = rows
        .filter (r) -> pids[r.pid]
        .map (r) ->
             pid: r.pid
             rowid: r.id
             cmd: JSON.parse(r.cmd)

    console.log JSON.stringify active

main = ->
    if c = argv.c or argv.child
        await run(c)
    else if argv.kill
        await kill(argv.kill)
    else if argv.out
        await print(argv.out, 'out')
    else if argv.err
        await print(argv.err, 'err')
    else if argv.running
        await running()
    else
        if argv._.length is 0
            process.stderr.write("error: command required, see --help\n")
            return 1
        fs.mkdirSync(data_dir) if not fs.existsSync(data_dir)
        await fork()

unless module.parent
    do -> process.exit await main()

module.exports = { main, sql, run }
