export SAMPLE_VIDEO=/opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4
export OUT_VIDEO=test_mp4.h264
export NVINFER_YML=/code/config_infer_primary.yml
export TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml
export TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so

./deepstream-app ${SAMPLE_VIDEO} ${OUT_VIDEO}
