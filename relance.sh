#!/bin/bash
if ! pgrep -f "./main" > /dev/null; then
  sleep $((RANDOM % 271 + 30))
  ./main &
fi
