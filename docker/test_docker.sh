mkdir -p workdir
INPUT=sample_720p.h264
docker run  --rm -it --name deepstream-app-container \
      --privileged \
      --net=host \
      --user=0 \
      --security-opt seccomp=unconfined  \
      --runtime nvidia \
      --gpus all \
      --device /dev/dri \
      --device /dev/dri \
      -v `pwd`/workdir:/workdir/ \
      deepstream-app:latest /workdir/sample_720p.h264 /workdir/output.avi
      #deepstream-app:latest bash #/workdir/sample_720p.h264 /workdir/output.avi

