#!/bin/bash

# Build deepstream gst libraries and test the install with a sample pipeline
# Usage: ./test.sh

set -eE -o functrace
export NAME="[test.sh] "
failure() {
  local lineno=$1
  local msg=$2
  echo "${NAME} Failed at $lineno: $msg"
}
trap '${NAME} failure ${LINENO} "$BASH_COMMAND"' ERR
echo "${NAME} STARTING "

# NOTE: sometimes gst-inspect-1.0 nvinfer (or other elements) throws an error.  Run this line to remove that!
rm -rf /root/.cache/gstreamer-1.0/registry.x86_64.bin
echo ""
echo ""
echo ""

echo "--(test)-- docker run environment variables are set (DISPLAY)"
if [ -z "$DISPLAY" ]; then
  echo "--(test:FAIL)-- docker run environment variables are set"
  echo "DISPLAY=(null)."
  echo "exit the docker then run this command, and try your docker run again: $ docker container prune"
else
  echo "--(test:PASS)-- docker run environment variables are set"
  echo "DISPLAY=$DISPLAY"
fi

PROJECT_MOUNT="$(test -f /code && echo 'yes' || echo 'no')"
if [[ "$PROJECT_MOUNT" == "no" ]]; then
  echo "--(test:FAIL)-- project mount to the correct directory"
else
  echo "--(test:PASS)-- project mount to the correct directory"
fi

NVINFER_CONFIG="$(test -f /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml && echo 'yes' || echo 'no')"
if [[ "$NVINFER_CONFIG" == "no" ]]; then
  echo "--(test:FAIL)-- nvinfer config exists"
else
  echo "--(test:PASS)-- nvinfer config exists"
fi

echo "--(helper)-- nvinfer config file paths that must change"
ABSOLUTE_PATH_1="$(grep -A0 model-file /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml)"
ABSOLUTE_PATH_2="$(grep -A0 proto-file /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml)"
ABSOLUTE_PATH_3="$(grep -A0 model-engine-file /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml)"
ABSOLUTE_PATH_4="$(grep -A0 labelfile-path /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml)"
ABSOLUTE_PATH_5="$(grep -A0 int8-calib-file /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml)"
echo "${ABSOLUTE_PATH_1}"
echo "${ABSOLUTE_PATH_2}"
echo "${ABSOLUTE_PATH_3}"
echo "${ABSOLUTE_PATH_4}"
echo "${ABSOLUTE_PATH_5}"

SAMPLE_VIDEO_EXISTS="$(test -f /opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4 && echo 'yes' || echo 'no')"
if [[ "$SAMPLE_VIDEO_EXISTS" == "no" ]]; then
  echo "--(test:FAIL)-- sample video exists"
else
  echo "--(test:PASS)-- sample video exists"
fi

# Sample video for your project
export SAMPLE_VIDEO=/opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4

# Nvidia file for nvinfer element
export NVINFER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml

# Nvidia files for nvtracker element
export TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml
export TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so

echo "***************************************";
echo "--(note)--    Clear gstreamer bin when you get errors with plugins not loading (gst-inspect-1.0 nvinfer)"
echo "rm -rf /root/.cache/gstreamer-1.0/registry.x86_64.bin"
echo ""
echo ""
echo ""
echo "***************************************";
echo "--(note)--    Try the following commands in your terminal to display videos"
echo "gst-play-1.0 /opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4 "
echo ""
echo "gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink "
echo ""
echo "gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! avdec_h264 ! videoconvert ! xvimagesink "
echo ""
echo ""
echo ""
echo "***************************************";
echo "--(note)--    Try the following commands to inspect element properties (some are set above)"
echo "gst-inspect-1.0 filesrc "
echo "gst-inspect-1.0 flvdemux "
echo "gst-inspect-1.0 flvmux "
echo "gst-inspect-1.0 filesink "
echo ""
echo ""
echo ""
echo "***************************************";
echo "--(note)--    Look at the element properties for the following using this command: "
echo "--(format)--  $ gst-inspect-1.0 <element-name>"
echo ""
echo "gst-inspect-1.0 filesrc       >>  location=${SAMPLE_VIDEO}"
echo "gst-inspect-1.0 nvinfer       >>  config-file-path=${NVINFER_YML}"
echo "gst-inspect-1.0 nvtracker     >>  ll-config-file=${TRACKER_YML}"
echo "gst-inspect-1.0 nvtracker     >>  ll-lib-file=${TRACKER_LIB}"
echo ""
echo ""
echo ""
echo "***************************************";
echo "Project files:"
echo "SAMPLE_VIDEO: ${SAMPLE_VIDEO}"
echo "NVINFER_YML: ${NVINFER_YML}"
echo "TRACKER_YML: ${TRACKER_YML}"
echo "TRACKER_LIB: ${TRACKER_LIB}"
echo ""
echo ""
echo ""
echo "***************************************";
echo "--(note)  After you've updated these NVINFER_YML with absolute paths (as mentioned in the README.md), you can run these commands to create a pipeline:"
echo "gst-launch-1.0 -e filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! nvv4l2h264enc ! h264parse ! flvmux ! filesink location=output.mp4 sync=false"
echo ""
echo "gst-launch-1.0 -e filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! xvimagesink sync=true"
echo ""
echo "${NAME} FINISHED "
