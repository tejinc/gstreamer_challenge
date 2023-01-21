xhost +
docker start  rad_challenge 
docker attach rad_challenge
#      --privileged \
#      --net=host \
#      --user=0 \
#      --security-opt seccomp=unconfined  \
#      --runtime nvidia \
#      --gpus all \
#      -e DISPLAY=${DISPLAY} \
#      --device /dev/dri \
#      -v /tmp/.X11-unix/:/tmp/.X11-unix \
#      -v `pwd`/code:/code \
#      -w /code \
#    rad_challenge bash

