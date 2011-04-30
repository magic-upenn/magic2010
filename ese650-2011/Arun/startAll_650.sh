#!/bin/bash

screen_list=`screen -ls | awk '/tached/ {print $1}' | sort`
if [ -n "$screen_list" ]; then
  echo "Currently running screens:"
  echo "$screen_list"
fi

StartFunction ()
{
  while read line; do
    if [[ -z "$line" || ${line:0:1} == "#" ]]; then
      continue
    fi
    name=${line%:*}
    cmd=${line#*:}
# Following substring search only works for bash version 3 (i.e. not on Mac OS X 10.4)
#    if [[ "$screen_list" =~ "${name}" ]]; then
# Instead, use awk for substring search:
    substr=`echo "$screen_list" | awk /\\\."$name"$/`
    if [ -n "$substr" ]; then
      echo "Session: $name already exists."
    else
      echo -n "Session: $name starting.."
      screen -S "$name" -dm $cmd   #$cmd needs to be unquoted
      if [ $? -eq 0 ]; then
        echo "done."
      else
        echo "$cmd failed."
      fi
    fi
  done
}

# List session names and commands for screen, delimited by ":"
# Stuff that was in previously
# h0:$MAGIC_DIR/drivers/Hokuyo/runHokuyo /dev/ttyACM0
# h1:$MAGIC_DIR/drivers/Hokuyo/runHokuyo /dev/ttyACM1
# slam:matlab -nodesktop -r startSlam
# mapfsm: matlab -nodesktop -r startMapfsm
# red: matlab -nodesktop -r startRed

StartFunction <<EOF
central:nice -n -5 central -s
mg:nice -n -5 $MAGIC_DIR/drivers/MicroGateway/runMicroGateway2 /dev/ttyUSB0
omnicam: matlab -nodesktop -r startOmniCam
frontcam: matlab -nodesktop -r startFrontCam
h0:$MAGIC_DIR/drivers/Hokuyo/runHokuyo /dev/ttyACM0
gps: matlab -nodesktop -r startGPS
EOF

exit
