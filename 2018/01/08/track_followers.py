#!/usr/bin/env python

# Source & Credit: https://gist.github.com/cdwfs/11240678

# Usage:
# 1) Install the Python Twitter Tools (PTT) from http://mike.verdone.ca/twitter/
#    (or just "easy_install twitter").
# 2) Run "twitter-follow -o blahblahblah" and follow the instructions to set up
#    OAuth. This gives the twitter-follow script read-only access to your account.
#    Technically, it doesn't even need to be *your* account that you authorize,
#    since the script is only querying public follower information.
# 3) Modify the value of "my_handle" to the username of the Twitter user whose
#    followers you'd like to track.
# 4) Run "python track_followers.py" to generate the initial list of followers,
#    which will be written to a file called "followers.txt".
# 5) Thereafter, run "python track_followers.py" to print a summary of changes to
#    your follower list to stdout, including follows, unfollows, and renames.
#    Personally, I added an hourly cron job to run "python track_followers.py >> log.txt"
#    to keep a running log of all follower changes.

import os.path
import subprocess
import sys
import time

my_handle = "@_xs"
followers_path = "followers.txt"

if sys.version_info.major == 3:
    import urllib.request
    my_urlopen = urllib.request.urlopen
    MyHttpError = urllib.error.HTTPError
elif sys.version_info.major == 2:
    import urllib2
    my_urlopen = urllib2.urlopen
    MyHttpError = urllib2.HTTPError

def does_user_exist(user):
    try:
        page = my_urlopen("http://twitter.com/%s" % user)
    except MyHttpError:
        return False
    return True

new_dict = {}
if len(sys.argv) == 2:
    # fake an update by passing a previously-generated follower list
    # mainly useful when I was converting from a flat follower list to
    # this script.
    timestamp = time.gmtime(os.path.getmtime(sys.argv[1]))
    new_file = open(sys.argv[1], "r")
    for line in new_file:
        userid,handle = line.strip().split('\t')
        new_dict[int(userid)] = handle
    new_file.close()
else:
    # Retrieve list of current followers
    timestamp = time.localtime()
    new_list = subprocess.check_output(["twitter-follow", "-o", "-r", "-i", my_handle]).decode("utf-8").strip().split('\n')
    for line in new_list:
        userid,handle = line.strip().split('\t')
        new_dict[int(userid)] = handle
new_userid_set = frozenset(list(new_dict.keys()))

if not os.path.exists(followers_path):
    sys.stderr.write("WARNING: %s not found; generating new list from scratch.\n" % followers_path)
else:
    # Read previous list of followers
    old_file = open(followers_path, "r")
    old_dict = {}
    for line in old_file:
        userid,handle = line.strip().split('\t')
        old_dict[int(userid)] = handle
    old_file.close()
    old_userid_set = frozenset(list(old_dict.keys()))

    # Compare old list to new and generate stats
    log_lines = []
    lost = []
    gained = []
    renamed = []
    for userid in old_userid_set - new_userid_set:
        lost.append( tuple([userid,old_dict[userid]]) )
    for userid in new_userid_set - old_userid_set:
        gained.append( tuple([userid,new_dict[userid]]) )
    for userid in old_userid_set & new_userid_set:
        if new_dict[userid] != old_dict[userid]:
            renamed.append( tuple([userid,old_dict[userid],new_dict[userid]]) )
    if lost or gained or renamed:
        log_lines.append("-------- %s:" % time.strftime("%Y-%m-%d %H:%M:%S %Z", timestamp))
        if lost:
            log_lines.append("%d follower(s) lost:" % len(lost))
            for userid,handle in sorted(lost):
                reason = ""
                if not does_user_exist(handle):
                    reason = "[account deleted]"
                log_lines.append("\t%10d %s %s" % (userid,handle,reason))
        if gained:
            log_lines.append("%d follower(s) gained:" % len(gained))
            for userid,handle in sorted(gained):
                log_lines.append("\t%10d %s" % (userid,handle))
        if renamed:
            log_lines.append("%d follower(s) renamed:" % len(renamed))
            for userid,old_name,new_name in sorted(renamed):
                log_lines.append("\t%10d %s -> %s" % (userid,old_name,new_name))
        log_lines.append("")
    for line in log_lines:
        print(line)

# Write new followers list, sorted by userid
new_file = open(followers_path, "w")
for userid in sorted(new_userid_set):
    new_file.write("%d\t%s\n" % (userid,new_dict[userid]))
new_file.close()
