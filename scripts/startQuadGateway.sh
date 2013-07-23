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
        substr=`echo "$screen_list" | awk /\\\."$name"$/`
        if [ -n "$substr" ]; then
            echo "Session: $name already exists."
        else
            echo -n "Session: $name starting.."
            screen -S "$name" -dm $cmd
            if [ $? -eq 0 ]; then
                echo "done."
            else
                echo "$cmd failed."
            fi
        fi
    done
}

StartFunction <<EOF
quadGateway:nice -n -15 $MAGIC_DIR/drivers/UAVCom/UAVReceive/quadDataPublish
april:nice -n -15 $MAGIC_DIR/drivers/UAVCom/UAVReceive/apriltags
EOF

exit