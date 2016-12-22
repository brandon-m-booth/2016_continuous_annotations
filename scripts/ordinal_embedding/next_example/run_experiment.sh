#!/bin/bash

xterm -e "cd /USC/Tools/NEXT/local; sudo ./docker_up.sh" &

sleep 10

xterm -e "cd strangefruit30; python -m SimpleHTTPServer 8999" &

sleep 5

python experiment_triplet.py
