#!/usr/bin/env python2

"""
Provides the fetch() method to make cached http requests, with a set of
properties that control behavior:

    import HTMLCache

    HTMLCache.bypass = True
    HTMLCache.cookie_file = "/tmp/cookies.txt"

    html = HTMLCache.fetch("http://www.google.com")

* `data_root`: Directory path where all data is stored (default:
  `~/.htmlcache`).

* `sleep`: Number of seconds to sleep after performing an http fetch. Note
  that cache hits do NOT incur this `sleep()` (default: 0).

* `bypass`: Bypass cache lookups (default: False).

* `cookie_file`: File path to a Netscape cookie file. Some on-the-fly
  corrections are made when reading the file to account for inconsistent
  file formats and cookielib's own anal parsing.

* `trace`: file-like for tracing messages

  *The file will be updated if the http response includes a `Set-Cookie`
  header*.

Also provides lookup() and store(), in case you don't want to use the
`requests` library (for instance, `mechanize`).
"""

import os
import json
import codecs
import shutil
import tempfile
import requests

from requests.packages.urllib3.exceptions import InsecureRequestWarning, InsecurePlatformWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
requests.packages.urllib3.disable_warnings(InsecurePlatformWarning)

data_root = os.path.join(os.environ['HOME'], '.htmlcache')
sleep = 0
bypass = False
cookie_file = None
trace = None
index = None

def _read_index():
    global index_file, index
    index_file = _make_file_path([data_root, 'index.json'])
    if index is None:
        if os.path.exists(index_file):
            index = json.load(codecs.open(index_file, 'r', 'utf-8'))
        else:
            index = {}
    return index

def _write_index():
    if not os.path.isdir(data_root):
        os.makedirs(data_root)

    tmp = tempfile.NamedTemporaryFile(delete=False)
    json.dump(index, codecs.open(tmp.name, 'w', 'utf-8'))
    shutil.move(tmp.name, index_file)

def _load_jar():
    import cookielib
    import re

    if not cookie_file:
        return cookielib.CookieJar()

    # cookielib won't even look at the rest of a cookie file if the first line
    # doesn't match a particular regex, so we always guarantee the magic_re
    # will succeed
    tmp = tempfile.NamedTemporaryFile(delete=False)
    tmp.write("# Netscape HTTP Cookie File\n")
    real = codecs.open(cookie_file, "r", 'utf-8')
    for line in real:
        f = line.split("\t")
        if re.search(r'^\s*#', line) or len(f) < 4:
            continue

        f[4] = str(int(float(f[4]))) if f[4] else ''
        while len(f) <= 6:
            f.append('')
        tmp.write("\t".join(f))
    tmp.close()

    jar = cookielib.MozillaCookieJar(tmp.name)
    jar.load()
    os.unlink(tmp.name)

    return jar

def _get_url(url, headers, stream=False, auth=None):
    jar = _load_jar()
    response = requests.get(url, headers=headers, cookies=jar, stream=stream, verify=False, auth=auth)
    if cookie_file:
        for cookie in response.cookies:
            jar.set_cookie(cookie)
        jar.save(cookie_file, True, True)

    return response

def _make_file_path(parts):
    dirname = os.path.join(*parts[:-1])
    if not os.path.isdir(dirname):
        os.makedirs(dirname)
    return os.path.join(*parts)

def _trace(url):
    if trace:
        trace.write("HTMLCache url: {}\n".format(url))
        data = json.dumps(index[url], sort_keys=True, indent=4, separators=(',', ': '))
        trace.write("HTMLCache data:{}\n".format(data))

def lookup(url):
    _read_index()
    if url in index:
        return codecs.open(index[url]['file']).read()
    return False

def store(url, html, headers=None):
    """Stores a url, it's html, and optionally its response headers."""
    import hashlib
    import time

    digest = hashlib.sha1(html.encode('utf-8')).hexdigest()
    filename = _make_file_path([data_root, 'html', digest])
    fh = codecs.open(filename, 'w', 'utf-8')
    fh.write(html)

    _read_index()
    index[url] = {
        'hash': digest,
        'file': filename,
        'size': os.path.getsize(filename),
        'time': time.time(),
        'headers': headers,
    }

    _trace(url)
    _write_index()

def fetch(url, headers=None, bin_file=False, auth=None, skip_cache=False):
    """ Return the html of a url. "url" is required, "headers" is an optional dict of
name-value pairs to include as http request headers, and "bin_file" is an
optional flag to set if the url is a binary file. If "bin_file" is set, then
the return value is the filepath of the fetched file."""
    import hashlib
    import time

    _read_index()

    if bypass or skip_cache or not url in index:
        if headers == None:
            headers = {}
        if not 'User-Agent' in headers:
            headers['User-Agent'] = 'curl/7.30.0'

        if bin_file:
            response = _get_url(url, headers, True, auth)
            digest = hashlib.sha1(url).hexdigest()
            filename = _make_file_path([data_root, 'bin', digest])
            fh = open(filename, 'wb')
            shutil.copyfileobj(response.raw, fh)
            index[url] = {
                'hash': digest,
                'file': filename,
                'size': os.path.getsize(filename),
                'time': time.time(),
                'headers': dict(response.headers),
            }
            _trace(url)
            _write_index()

        else:
            response = _get_url(url, headers, False, auth)
            store(url, response.text, dict(response.headers))

        time.sleep(sleep)

    if bin_file:
        return index[url]['file']
    else:
        return lookup(url)

def fetch_with_headers(*args, **kwargs):
    html = fetch(*args, **kwargs)
    if html:
        url = args[0]
        headers = dict((k.lower(), v) for k,v in index[url]['headers'].iteritems())
    return [html, headers]

if __name__ == '__main__':
    bypass = True

    fetch("http://www.google.com")

    url = "http://aws.brewingcode.net/alex/cookie.php"
    headers = {'Referer': 'http://www.google.com'}
    cookie_file = '/tmp/abc'

    print fetch(url, headers=headers)

    print fetch("http://docs.python.org/2/_static/py.png", bin_file=True)

