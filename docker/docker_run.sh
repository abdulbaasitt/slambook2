#!/bin/bash
set -e

echo "Running from: $PWD"
echo "Make sure you are in the slambook2 root directory."

docker run -it \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /home/jacobs/ws/slambook2:/slambook2 \
  --gpus all \
  --name slambook2 \
  slambook2:latest \
  /bin/bash
