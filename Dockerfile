FROM kubevirt/container-disk-v1alpha:v0.13.7

LABEL maintainer="Juan Manuel Torres <juanmanuel.torres@aventurabinaria.es>"

ARG OS_NAME="fedora"
ARG OS_VERSION="36"
ARG IMAGE_URL="https://ftp.cica.es/fedora/linux/releases/36/Cloud/x86_64/images/Fedora-Cloud-Base-36-1.5.x86_64.qcow2"
ARG FILE_NAME="os_xxx.img"
ARG IMAGE_NAME="os_xxx"
ARG IMAGE_EXTENSION="qcow2"

RUN echo "Download: $IMAGE_URL FILE: $FILE_NAME"; \
	set -x \
	&& yum update --releasever 28 -y \
	&& yum install -y findutils --releasever 28

RUN curl -kfSL $IMAGE_URL -o /disk/$FILE_NAME ; if [ $? != 0 ]; then exit 1; fi 

RUN KEY_LOOP="true"; \
while [ $KEY_LOOP == "true" ]; do \
	echo "Process extension: $IMAGE_EXTENSION"; \
	if [ "$IMAGE_EXTENSION" == "qcow2" ] ; then \
        modprobe nbd; \

        qemu-nbd --connect=/dev/nbd0 /disk/$FILE_NAME; \

        mkdir /mnt/ubuntu; \

        mount /dev/nbd0p1 /mnt/ubuntu; \

        mount -t proc proc /mnt/ubuntu/proc/; \

        chroot /mnt/ubuntu dnf -y install dnf-plugins-core; \
        chroot /mnt/ubuntu dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; \
        chroot /mnt/ubuntu dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin; \

        umount /mnt/ubuntu/proc; \

        sync; \

        umount /mnt/ubuntu; \
        qemu-nbd --disconnect /dev/nbd0; \

		qemu-img convert -f qcow2 -O raw /disk/$FILE_NAME /disk/$OS_NAME.img; \
		rm -rf /disk/$FILE_NAME; \
		KEY_LOOP="false"; \
	elif [ "$IMAGE_EXTENSION" == "vmdk" ] ; then \
		qemu-img convert -f vmdk -O raw /disk/$FILE_NAME /disk/$OS_NAME.img; \
		rm -rf /disk/$FILE_NAME; \
		KEY_LOOP="false"; \
	elif [ "$IMAGE_EXTENSION" == "bz2" ] ; then \
		bunzip2 /disk/$FILE_NAME; \
		rm -rf /disk/$FILE_NAME; \
		export FILE_NAME=$(ls -l /disk | grep "^-" | awk '{ print $9 }' | grep -v "$FILE_NAME"); \
		echo "New file name: $FILE_NAME"; \
		export IMAGE_EXTENSION=$(echo $FILE_NAME | cut -d"." -f2); \
	elif [ "$IMAGE_EXTENSION" == "img" ] ; then \
		if [ ! -f /disk/$OS_NAME.img ]; then \
			mv /disk/$FILE_NAME /disk/$OS_NAME.img; \
			ls /disk/; \
		fi ;\
		KEY_LOOP="false"; \
	else \
		KEY_LOOP="false"; \
	fi \
done
