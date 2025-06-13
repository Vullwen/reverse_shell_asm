#!/bin/bash
./main

while true; do
  if ! pgrep -f "./main" > /dev/null; then
    sleep $((RANDOM % 271 + 30))
    ./main &
  fi
  sleep 10  
done

