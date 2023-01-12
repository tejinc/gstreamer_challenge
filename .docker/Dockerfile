FROM nvcr.io/nvidia/deepstream:6.1-devel

ENV NVIDIA_DRIVER_CAPABILITIES all
ENV NVIDIA_VISIBLE_DEVICES all
ENV DEBIAN_FRONTEND noninteractive

COPY test.sh /start/test.sh
RUN apt-get update -yqq && apt-get install -yqq \
    ffmpeg vim nano \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgstrtspserver-1.0-dev \
    libx11-dev \
    graphviz \
    gstreamer1.0-plugins-base-apps
RUN rm -rf /root/.cache/gstreamer-1.0/registry.x86_64.bin
CMD ["bash"]