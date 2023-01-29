# kubevirt-guide

## Debian
```shell
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: debian
spec:
  running: false
  template:
    metadata:
      labels: 
        kubevirt.io/size: small
        kubevirt.io/domain: debian
    spec:
      domain:
        cpu:
          cores: 2
        devices:
          disks:
            - name: containervolume
              disk:
                bus: virtio
            - name: cloudinitvolume
              disk:
                bus: virtio
          interfaces:
          - name: default
            bridge: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      volumes:
        - name: containervolume
          containerDisk:
            image: tedezed/debian-container-disk:9.0
        - name: cloudinitvolume
          cloudInitNoCloud:
            userData: |-
              #cloud-config
              chpasswd:
                list: |
                  debian:debian
                  root:root
                expire: False
EOF
```

## 参考
* [系统镜像](https://github.com/Tedezed/kubevirt-images-generator)
