FROM kubevirt/container-disk-v1alpha:v0.13.7

ARG OS_NAME="example_os"
ARG OS_VERSION="0.0"
ARG IMAGE_URL="https://example.com/os_xxx.img"
ARG FILE_NAME="os_xxx.img"
ARG IMAGE_NAME="os_xxx"
ARG IMAGE_EXTENSION="img"

RUN dnf -y install dnf-plugins-core
RUN dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
RUN dnf install docker-ce docker-ce-cli containerd.io -y
