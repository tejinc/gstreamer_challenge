#!/bin/bash

### Install Nvidia runtime on local computer (not inside docker)
# Example usage: ./install_nvidia-runtime.sh

export NAME="[install_nvidia-runtime.sh] "

set -eE -o functrace
failure() {
  local lineno=$1
  local msg=$2
  echo "${NAME} Failed at $lineno: $msg"
}
trap '${NAME} failure ${LINENO} "$BASH_COMMAND"' ERR

## Script start
echo "${NAME} STARTING "

wget https://nvidia.github.io/nvidia-docker/gpgkey --no-check-certificate
sudo apt-key add gpgkey
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L "https://nvidia.github.io/nvidia-docker/${distribution}/nvidia-docker.list" | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update -y;

echo "${NAME} Install base apt package "
sudo apt-get install -y -qq \
  nvidia-container-runtime

echo "${NAME} Install docker engine deps "
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "${NAME} Install docker daemon deps "
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo pkill -SIGHUP dockerd

echo "${NAME} FINISHED "