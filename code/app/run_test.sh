export SAMPLE_VIDEO=/opt/nvidia/deepstream/deepstream/samples/streams/sample_720p.h264
export OUT_VIDEO=test.avi
export NVINFER_YML=/code/config_infer_primary.yml
export TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml
export TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so

./deepstream-app ${SAMPLE_VIDEO} ${OUT_VIDEO}
