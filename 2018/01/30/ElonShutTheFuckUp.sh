#!/bin/bash
# https://twitter.com/U_1F410/status/1000494039148490753
# Wrote a bot as a bash oneliner, reply to every @elonmusk tweet with "Shut the fuck up"
export EBT=$(t ti -cn 1 elonmusk|egrep -o"^[0-9]+");[ $(cat ./.ebtweet) == $EBT ] && echo no ||(echo $EBT > ./.ebtweet && t reply $EBT "Shut the fuck up")
