#!/usr/bin/env python2

import json
import sys
import re
import os
import re
import urllib
import HTMLCache
import isodate
import optparse

opts = False

def dump_json(data, prepend):
    s = json.dumps(data, indent=2, separators=(', ', ': '))
    sys.stderr.write('{}\n'.format(re.sub(r'^', prepend, s, flags=re.MULTILINE)))

def api_call(path, data):
    init_opts()

    if opts.verbose:
        HTMLCache.trace = sys.stderr
        sys.stderr.write('path: {}\n'.format(path))
        dump_json(data, '> ')

    if opts.fetch:
        HTMLCache.bypass = True

    data['key'] = os.environ['YOUTUBE_API_KEY']

    query_string = urllib.urlencode(data)
    url = 'https://www.googleapis.com/youtube/v3/{}?{}'.format(path, query_string)
    response = json.loads(HTMLCache.fetch(url))

    if opts.verbose:
        dump_json(response, '< ')

    return response

def check_items(data):
    if not 'items' in data:
        sys.stderr.write('"items" was not in API response\n')
        dump_json(data, '! ')
        sys.exit(1)

def make_time(s):
    h = s / 3600
    s -= 3600 * h
    m = s / 60
    s -= 60 * m
    return '{:02d}:{:02d}:{:02d}'.format(h, m, s)

def get_playlist(playlist_id):
    videos = {}
    args = {
        'part':'snippet',
        'maxResults':50,
        'playlistId':playlist_id
    }

    while 1:
        response = api_call('playlistItems', args)

        check_items(response)

        for item in response['items']:
            video_id = item['snippet']['resourceId']['videoId']

            videos[video_id] = {
                'title': item['snippet']['title'],
                'id': video_id,
                'views': None
            }

        stats = api_call('videos', {
            'part': 'statistics,snippet,contentDetails',
            'id': ','.join(filter(lambda x: videos[x]['views'] == None, videos.keys())),
            'maxResults':50
        })

        check_items(stats)

        for stat in stats['items']:
            v = {}
            v['views'] = stat['statistics']['viewCount']
            v['published'] = stat['snippet']['publishedAt']
            v['title'] = stat['snippet']['title']
            v['duration'] = stat['contentDetails']['duration']
            v['likes'] = stat['statistics']['likeCount']
            v['url'] = 'http://www.youtube.com/watch?v={}'.format(stat['id'])

            # convert duration from ISO8601 "PT<x>M<y>S" duration
            v['duration'] = int(isodate.parse_duration(v['duration']).total_seconds())
            v['time'] = make_time(int(v['duration']))

            videos[stat['id']] = v

        if 'nextPageToken' in response:
            args['pageToken'] = response['nextPageToken']
        else:
            break

    return videos

def get_channel(channel_id):
    args = {
        'part':'contentDetails',
        'maxResults':50,
        'id':channel_id
    }

    channel = api_call('channels', args)
    check_items(channel)

    return get_playlist(channel['items'][0]['contentDetails']['relatedPlaylists']['uploads'])

def init_opts():
    parser = optparse.OptionParser("""
Print a tab-separated list to stdout of all videos in a youtube
playlist or channel.

Shortcuts:
  -p blh      Husky's "Bronze League Heroes" playlist
  -c husky    Husky's Starcraft channnel

Raw API calls are possible with --api/-a, which takes a PATH and a
block of json as arguments, eg:

  -a channels '{"part":"contentDetails","forUsername":"bkraz333"}'""")
    parser.add_option('--playlist', '-p', metavar="PLAYLIST",
        help="get videos in a playlist (id OR url)")
    parser.add_option('--channel', '-c', metavar="CHANNEL",
        help="get videos uploaded to this channel (id OR url)")
    parser.add_option('--user', '-u', metavar="USERNAME",
        help="get videos uploaded by USERNAME")
    parser.add_option('--verbose', '-v', action='store_true',
        help="print incoming and outgoing JSON data on stderr")
    parser.add_option('--more', '-m', action="store_true",
        help="include more columns in output")
    parser.add_option('--header', '-d', action="store_true",
        help="include headers in first line of output")
    parser.add_option('--fetch', '-f', action="store_true",
        help="fetch pages (bypass the html cache)")
    parser.add_option('--sort', '-s', default="views",
        help="sort based on this (default: 'views')")
    parser.add_option('--api', '-a', nargs=2,
        help=optparse.SUPPRESS_HELP)

    global opts
    if not opts:
        (opts, _) = parser.parse_args()

def main():
    reload(sys)
    sys.setdefaultencoding('utf-8')

    init_opts()

    if opts.api:
        args = json.loads(opts.api[1])
        dump_json(api_call(opts.api[0], args), '')
        return

    if opts.playlist:
        m = re.search(r'list=([\w\-]+)', opts.playlist)
        if m:
            opts.playlist = m.group(1)
        elif opts.playlist.lower() == 'blh':
            opts.playlist = 'PLooJOgo-8bToEW-PRePfc0q2P8RqbTpev'

        videos = get_playlist(opts.playlist)

    elif opts.channel:
        m = re.search(r'/channel/([\w\-]+)', opts.channel)
        if m:
            opts.channel = m.group(1)
        elif opts.channel.lower() == 'husky':
            opts.channel = 'UCZ8D7Qvm0YHm0vZKFl-AFdA'

        videos = get_channel(opts.channel)

    elif opts.user:
        channel = api_call('channels', {'forUsername':opts.user, 'part':'contentDetails'})
        check_items(channel)
        videos = get_playlist(channel['items'][0]['contentDetails']['relatedPlaylists']['uploads'])

    else:
        sys.stderr.write('nothing to do, try --help\n')
        sys.exit(1)

    header = ['views', 'title', 'url']
    if opts.more:
        for i in ['likes', 'time', 'duration', 'published']:
            header.insert(1, i)

    if opts.header:
        print "\t".join(header)

    sort_key = lambda x: int(x[opts.sort])
    if opts.sort in ['published', 'time']:
        sort_key = lambda x: str(x[opts.sort])

    for video in sorted(videos.values(), key=sort_key, reverse=True):
        print "\t".join(str(video[i]) for i in header)

if __name__ == '__main__': main()

