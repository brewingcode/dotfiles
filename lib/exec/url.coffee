# url parse (default), encode, or decode

url = require 'url'
minimist = require 'minimist'
fs = require 'fs'
pd = require 'parse-domain'
{ encode, decode } = require('html-entities')

argv = minimist process.argv.slice(2),
    boolean: ['e', 'encode', 'd', 'decode', 'E', 'enc-ent', 'D', 'dec-ent',
        'tld', 'domain', 'fulldomain', 'defrag' ]

qs = (parts, indent) ->
    if parts.query and Object.keys(parts.query).length
        return ( "#{k}=#{v}" for k,v of parts.query ).join "#{indent}&"
    return ''

handle = (s) ->
    try
        s = s.trim()
        if argv.e or argv.encode
            console.log encodeURIComponent s
        else if argv.d or argv.decode
            console.log decodeURIComponent s
        else if argv.E or argv['to-entities']
            console.log entities.encode(s)
        else if argv.D or argv['from-entities']
            console.log entities.decode(s)
        else if argv.tld
            console.log pd(s).tld
        else if argv.domain
            parts = pd(s)
            console.log "#{parts.domain}.#{parts.tld}"
        else if argv.fulldomain
            parts = pd(s)
            console.log "#{parts.subdomain}.#{parts.domain}.#{parts.tld}"
        else
            p = url.parse s, true
            out = ''
            out += "#{p.protocol}//" if p.protocol
            out += "#{p.auth}@" if p.auth
            out += p.host if p.host
            out += p.pathname if p.pathname
            if p.query and Object.keys(p.query).length
                out += '\n  ?'
                out += qs(p, '\n  ')
            if p.hash
                if argv.defrag
                    frag = p.hash.match(/^#(.*)/).slice(1)
                    q = url.parse "http://foo.com?#{frag}", true
                    out += '\n  #'
                    out += qs(q, '\n    ')
                else
                    out += "\n  #{p.hash}"
            console.log out

if argv._.length
    handle(arg) for arg in argv._
else
    for line in fs.readFileSync('/dev/stdin', 'utf8').split(/\n+/)
        handle(line.trim()) if line
