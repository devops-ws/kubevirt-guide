```shell
apt update -y
apt -y install libguestfs-tools

yum update -y
yum -y install libguestfs-tools

wget https://ftp.cica.es/fedora/linux/releases/36/Cloud/x86_64/images/Fedora-Cloud-Base-36-1.5.x86_64.qcow2 --no-check-certificate
export LIBGUESTFS_BACKEND=direct

virt-customize -a Fedora-Cloud-Base-36-1.5.x86_64.qcow2 --install [dnf-plugins-core]
virt-customize -a Fedora-Cloud-Base-36-1.5.x86_64.qcow2 --mkdir /etc/apt/keyrings
virt-customize -a Fedora-Cloud-Base-36-1.5.x86_64.qcow2 --run-command "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
```

## 上传文件
```shell
virt-customize -a rhel-server-7.6.qcow2 --upload rhsm.conf:/etc/rhsm/rhsm.conf
```
