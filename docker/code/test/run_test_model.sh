export SAMPLE_VIDEO=/opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4
export NVINFER_YML=/code/config_infer_primary.yml
export TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml
export TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so

gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! progressreport update-freq=1 !xvimagesink

