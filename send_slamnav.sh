#!/bin/bash
echo "Enter other robot ip :"
read ipaddr
echo "ip: $ipaddr"

scp -p /home/odroid/code/build-SLAMNAV-Desktop-Release/SLAMNAV odroid@$ipaddr:/home/odroid
#scp -p /home/odroid/0313/build-SLAMNAV-Desktop-Release/SLAMNAV odroid@$ipaddr:/home/odroid

