# Rad Coding Challenge


# Table of contents
1. [Getting Started](#getting-started)
2. [Challenge Description](#challenge-description)
3. [Submission Requirements](#submission-requirements)
4. [Review](#review)


## Getting Started

----

__Support Requests__

Team support is a big part of RAD's team culture. 

If you have a roadblock, ask the VMS team lead for support so that you can make progress. Here is what we offer:

- Q/A through email
- Q/A through 15 minute video call
 
There is no limit to the number of support requests you have, but we do encourage you to organize your thoughts into a coherent support request.


----

__Sign up for Nvidia__

https://ngc.nvidia.com/signin

- add your email address, and it will bring you to create a new account
- it will prompt you to check email to validate your account
- once logged in, click your user on the top right and select "Setup"
- click on "Get API Key"
- click on "Generate API Key"
- follow the instructions below, and save this information somewhere, so you can log in later.  
- You can always generate a new key if you lose your key, so don't worry!

__Initial Project Setup__

You should be able to complete this section fairly quickly.
- all the following are tested and able to run on our developer's laptops
- your laptop may be different so please do not hesitate to ask questions if something doesn't immediately work for you!


- inside the folder `laptop_setup` run the following scripts (optional if you've already got these working)

```bash
install_docker.sh
install_nvidia-runtime.sh
```

- pull the docker container

```bash
# login to nvidia's container registry
docker login nvcr.io
# pull it!
docker pull nvcr.io/nvidia/deepstream:6.1-devel
```

- build the sample Dockerfile

```bash 
docker build -t rad_challenge `pwd`/.docker/ -f `pwd`/.docker/Dockerfile
```

- run the docker container
- the notes printed to terminal in `test.sh` are important ... so study them and ask questions!

```bash
# enable docker to play videos
xhost +
# run!
docker run -it --name rad_challenge \
	    --privileged \
	    --net=host \
	    --user=0 \
	    --security-opt seccomp=unconfined  \
	    --runtime nvidia \
	    --gpus all \
	    -e DISPLAY=${DISPLAY} \
	    --device /dev/dri \
	    -v /tmp/.X11-unix/:/tmp/.X11-unix \
	    -v `pwd`/code:/code \
	    -w /code \
		rad_challenge bash

root@user:/code# cd /start
root@user:/start# ./test.sh
```

----

__Getting an AI pipeline to run__

If you find there is a lot of new content, don't worry, we love inquisitive thinkers and are happy to answer questions.
- it is _highly_ advised that you are able to run this command inside the docker container before starting the coding
- a video screen should pop up and display the video with bounding boxes around objects
- if you have *any* problems with this, request support!

- from inside the docker container, copy this file to your project directory:

```bash
cp /opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_infer_primary.yml /code/config_infer_primary.yml
```

- then from outside docker change permissions
```bash
chmod 777 code -R 
chown $USER:$USER code -R 
```

- update the following keys with absolute paths:

```bash
  model-file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel
  proto-file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.prototxt
  model-engine-file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b30_gpu0_int8.engine
  labelfile-path: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/labels.txt
  int8-calib-file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/cal_trt.bin
```

- run a pipeline 

```bash
export SAMPLE_VIDEO=/opt/nvidia/deepstream/deepstream/samples/streams/sample_1080p_h264.mp4
export NVINFER_YML=/code/config_infer_primary.yml
export TRACKER_YML=/opt/nvidia/deepstream/deepstream-6.1/samples/configs/deepstream-app/config_tracker_NvDCF_perf.yml
export TRACKER_LIB=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvmultiobjecttracker.so

gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! xvimagesink
```

- congrats, you ran an AI pipeline!

----

__update your config file with the new serialized engine file__

You might have noticed that it took a while for the video to start, and if you read the logs there were a few `WARNING` logs

- search your terminal for this: `serialize cuda engine to file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector`
- note that below you can see `resnet10.caffemodel_b1_gpu0_int8.engine`
```bash
root@mat:/code# gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! xvimagesink
Setting pipeline to PAUSED ...
WARNING: ../nvdsinfer/nvdsinfer_model_builder.cpp:1482 Deserialize engine failed because file path: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b30_gpu0_int8.engine open error
0:00:00.901846508    88 0x563744a75a30 WARN                 nvinfer gstnvinfer.cpp:643:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Warning from NvDsInferContextImpl::deserializeEngineAndBackend() <nvdsinfer_context_impl.cpp:1888> [UID = 1]: deserialize engine from file :/opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b30_gpu0_int8.engine failed
0:00:00.915142523    88 0x563744a75a30 WARN                 nvinfer gstnvinfer.cpp:643:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Warning from NvDsInferContextImpl::generateBackendContext() <nvdsinfer_context_impl.cpp:1993> [UID = 1]: deserialize backend context from engine from file :/opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b30_gpu0_int8.engine failed, try rebuild
0:00:00.915159031    88 0x563744a75a30 INFO                 nvinfer gstnvinfer.cpp:646:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Info from NvDsInferContextImpl::buildModel() <nvdsinfer_context_impl.cpp:1914> [UID = 1]: Trying to create engine from model files
0:00:19.093704062    88 0x563744a75a30 INFO                 nvinfer gstnvinfer.cpp:646:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Info from NvDsInferContextImpl::buildModel() <nvdsinfer_context_impl.cpp:1946> [UID = 1]: serialize cuda engine to file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b1_gpu0_int8.engine successfully
INFO: ../nvdsinfer/nvdsinfer_model_builder.cpp:610 [Implicit Engine Info]: layers num: 3
0   INPUT  kFLOAT input_1         3x368x640       
1   OUTPUT kFLOAT conv2d_bbox     16x23x40        
2   OUTPUT kFLOAT conv2d_cov/Sigmoid 4x23x40 

0:00:19.035671983    72 0x5597b0b02ca0 INFO                 nvinfer gstnvinfer_impl.cpp:328:notifyLoadModelStatus:<nvinfer0> [UID 1]: Load new model:/code/config_infer_primary.yml sucessfully
Pipeline is PREROLLING ...
Pipeline is PREROLLED ...
Setting pipeline to PLAYING ...
New clock: GstSystemClock

```

- mine looked like this
```bash
 serialize cuda engine to file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b1_gpu0_int8.engine successfully 
```

- so I updated `code/config_infer_primary.yml` with this

```yml
 model-engine-file: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b1_gpu0_int8.engine
```

- the next time you run it, you'll notice it starts running much faster than the previous run and there are no `WARNING` logs.
- this is because the nvinfer element is smart, and if it finds `model-engine-file` then it doesn't need to re-create it!

```bash
root@mat:/code# gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! xvimagesink
Setting pipeline to PAUSED ...
0:00:01.413647346   122 0x55dab0434ca0 INFO                 nvinfer gstnvinfer.cpp:646:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Info from NvDsInferContextImpl::deserializeEngineAndBackend() <nvdsinfer_context_impl.cpp:1900> [UID = 1]: deserialized trt engine from :/opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b1_gpu0_int8.engine
INFO: ../nvdsinfer/nvdsinfer_model_builder.cpp:610 [Implicit Engine Info]: layers num: 3
0   INPUT  kFLOAT input_1         3x368x640       
1   OUTPUT kFLOAT conv2d_bbox     16x23x40        
2   OUTPUT kFLOAT conv2d_cov/Sigmoid 4x23x40         

0:00:01.425908810   122 0x55dab0434ca0 INFO                 nvinfer gstnvinfer.cpp:646:gst_nvinfer_logger:<nvinfer0> NvDsInferContext[UID 1]: Info from NvDsInferContextImpl::generateBackendContext() <nvdsinfer_context_impl.cpp:2003> [UID = 1]: Use deserialized engine model: /opt/nvidia/deepstream/deepstream-6.1/samples/models/Primary_Detector/resnet10.caffemodel_b1_gpu0_int8.engine
0:00:01.426689761   122 0x55dab0434ca0 INFO                 nvinfer gstnvinfer_impl.cpp:328:notifyLoadModelStatus:<nvinfer0> [UID 1]: Load new model:/code/config_infer_primary.yml sucessfully
Pipeline is PREROLLING ...
Pipeline is PREROLLED ...
Setting pipeline to PLAYING ...
New clock: GstSystemClock

```

----

# Challenge Description

----

__overview__

Create a gstreamer pipeline in C++ with the following capabilities:

1. reads from an mp4 file
2. runs a neural network with tracking and on-screen display
3. outputs to mp4 file

We expect you to have challenges with the following elements in a pipeline:
- qtdemux -- Demuxes a .mov file into raw or compressed audio and/or video streams. -- https://gstreamer.freedesktop.org/documentation/isomp4/qtdemux.html?gi-language=c
- nvstreammux --The Gst-nvstreammux plugin forms a batch of frames from multiple input sources. --a= https://docs.nvidia.com/metropolis/deepstream/dev-guide/text/DS_plugin_gst-nvstreammux.html
- nvinfer -- 
- nvtracker
- nvosd

Reading about the following will help in building good questions for support
- [gst_element_get_request_pad](https://gstreamer.freedesktop.org/documentation/gstreamer/gstelement.html?gi-language=c#gst_element_get_request_pad)
- [gst_element_get_static_pad](https://gstreamer.freedesktop.org/documentation/gstreamer/gstelement.html?gi-language=c#gst_element_get_static_pad)

----

__Program characteristics__

1. the output file can be run with this command: `gst-play-1.0 output.mp4`
2. the output file has bounding boxes on detected objects
3. the program terminates after it is finished running.

----

# Submission Requirements

----

__email submission__

Once completed, Email the team lead (matt.m@radskunkworks.com) to notify your submission.  

- Include any additional information (I have attached a zip folder, here is the git link, etc).

- Your submission has scope criteria: hard requirements and soft requirements.  

- Please ensure that all hard requirements are met before adding soft requirements.

----

__hard requirements__

- update this README.md with instructions to build/run your project 
    - yes, we will actually build and run your code!
- a dockerized project
- a Makefile to build/run docker containers
- the gstreamer pipeline is programmed with C++

----

__soft requirements__

- create a git repository (tracking many commits is preferred, and you will not be judged on the content of your commits unless you only have one commit!)
- include any coding practices (linting, CI-CD, testing, CMake builds, logging, etc)
- add a callback to parse through nvidia's metadata and print it to terminal

```C++
GstPad *probe_pad = NULL;
std::string pad_name = "sink";
probe_pad = gst_element_get_static_pad(pipeline.nvosd, pad_name.c_str());
gst_pad_add_probe(probe_pad, GST_PAD_PROBE_TYPE_BUFFER, (gpointer) &callbacks::parse_meta, NULL, NULL);
```

```C++
GstPadProbeReturn callbacks::meta_parse(GstPad *pad, GstPadProbeInfo *info, gpointer u_data)
{
    GstBuffer *buf = (GstBuffer *)info->data;
    guint num_rects = 0;
    NvDsObjectMeta *obj_meta = NULL;
    guint vehicle_count = 0;
    guint person_count = 0;
    NvDsMetaList *l_frame = NULL;
    NvDsMetaList *l_obj = NULL;
    NvDsDisplayMeta *display_meta = NULL;

    NvDsBatchMeta *batch_meta = gst_buffer_get_nvds_batch_meta(buf);
    // add some code
    return GST_PAD_PROBE_OK;
}
```

----

# Review
A 30 minute discussion about your submission with our team members.

----




gst-launch-1.0 filesrc location=${SAMPLE_VIDEO} ! qtdemux ! h264parse ! nvv4l2decoder ! m.sink_0 nvstreammux name=m batch-size=1 width=1920 height=1080 gpu-id=0 ! nvinfer config-file-path=${NVINFER_YML} batch-size=1 unique-id=1 ! queue ! nvvideoconvert ! nvdsosd ! nvvideoconvert ! xvimagesink
We expect you to have challenges with the following elements in a pipeline:
- qtdemux -- Demuxes a .mov file into raw or compressed audio and/or video streams. -- https://gstreamer.freedesktop.org/documentation/isomp4/qtdemux.html?gi-language=c
- nvstreammux --The Gst-nvstreammux plugin forms a batch of frames from multiple input sources. --a= https://docs.nvidia.com/metropolis/deepstream/dev-guide/text/DS_plugin_gst-nvstreammux.html
- nvinfer -- self explanatory
- nvtracker -- https://docs.nvidia.com/metropolis/deepstream/dev-guide/text/DS_plugin_gst-nvtracker.html
- nvosd -- draws bounding box

__Deepstream-app Instruction__

1. First build `rad_challenge`
2. In the top directory (containing `code`, `Makefile`, etc), do
```bash
# build the container
make
```
This will create the image deepstream-app. Next we will process a sample video.
```bash
mkdir workdir

docker run --name rad_challenge_copy rad_challenge

docker cp rad_challenge_copy:/opt/nvidia/deepstream/deepstream/samples/streams/sample_720p.h264 workdir/

docker run --rm --name deepstream-app-container \
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
```

The command will create a working directory, bind mount it to the docker container, and allow deepstream-app 
to process the sample video file. 
