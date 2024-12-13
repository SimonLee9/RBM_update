#!/bin/bash
echo "Enter other robot ip :"
read ipaddr
echo "ip: $ipaddr"

scp -p /home/odroid/code/build-RB_FMS-Desktop-Release/RB_FMS odroid@$ipaddr:/home/odroid
