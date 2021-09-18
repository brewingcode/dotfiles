#!/usr/bin/env python2

# adapted from http://zeflo.com/2015/the-reddit-button/

import urllib2
import re
import websocket # pip install websocket-client, NOT websocket
import json
import sys

req = urllib2.Request('http://www.reddit.com/r/thebutton', None)
response = urllib2.urlopen(req)
page = response.read()
found = re.search('wss://(.+?)"', page)

# if successfull
if found:
  print '\t'.join(['timer', 'min', 'participants'])

  url = "wss://" + found.group(1)
  ws = websocket.create_connection(url)
  fewest = 60

  while True:
    result =  ws.recv()
    result = json.loads(result)
    seconds_left = result['payload']['seconds_left']
    participants = result['payload']['participants_text']
    if seconds_left < fewest:
      fewest = seconds_left
    print  '\t'.join(str(x) for x in [seconds_left,fewest,participants])

  ws.close()

else:
  sys.stderr.write('no websocket url found at /r/thebutton')
