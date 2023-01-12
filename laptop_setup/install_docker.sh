#!/bin/bash

### Fresh install of docker
# Example usage: ./install_docker.sh

export NAME="[install_docker.sh] "

set -eE -o functrace
failure() {
  local lineno=$1
  local msg=$2
  echo "${NAME} Failed at $lineno: $msg"
}
trap '${NAME} failure ${LINENO} "$BASH_COMMAND"' ERR

## Script start
echo "${NAME} STARTING "

sudo apt-get update -y -qq && sudo apt-get install -y -qq apt-utils
sudo apt-get install -y -qq \
  git \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo "${NAME} starting docker installation steps, visit link for debugging and more info: https://get.docker.com/"
cd ~; curl -fsSL https://get.docker.com -o get-docker.sh
cd ~; sh get-docker.sh
cd ~; rm get-docker.sh

echo "${NAME} docker post-installation: adding user to the docker group"
sudo usermod -aG docker "${USER}"
newgrp docker
sudo touch /home/"$USER"/.docker
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
docker run hello-world
echo "${NAME} FINISHED "