#!/bin/bash
echo "Enter other robot ip :"
read ipaddr
echo "ip: $ipaddr"

scp -p /home/odroid/code/build-Map_Editor-Desktop-Release/Map_Editor odroid@$ipaddr:/home/odroid
