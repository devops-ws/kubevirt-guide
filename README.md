# kubevirt-guide

```shell
export VERSION=v0.58.0
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml
```

```shell
hd i virtctl
```

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
              bootcmd:
                - apt-get update -y
                - apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https
                - mkdir -p /etc/apt/keyrings
                - curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                - apt-get update -y
                - apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
              chpasswd:
                list: |
                  debian:debian
                  root:root
                expire: False
EOF
```

```shell
virtctl start debian
virtctl console debian
```

## 上传 ISO
```shell
export CDI=v1.48.1
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-operator.yaml
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-cr.yaml

kubectl apply -f - <<EOF 
apiVersion: v1
kind: Service
metadata:
  labels:
    cdi.kubevirt.io: cdi-uploadproxy
  name: cdi-uploadproxy-nodeport
  namespace: cdi
spec:
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - nodePort: 31001
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    cdi.kubevirt.io: cdi-uploadproxy
  sessionAffinity: None
  type: NodePort
EOF

virtctl image-upload --image-path JZ_WIN10_X64_V2023.02.iso --pvc-name=win11 --uploadproxy-url https://localhost:30001 --insecure --access-mode=ReadWriteMany --pvc-size=7G

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: winhd
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 35Gi
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: iso-win10
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: iso-win10
    spec:
      domain:
        cpu:
          cores: 6
        devices:
          disks:
          - bootOrder: 1
            cdrom:
              bus: sata
            name: cdromiso
          - bootOrder: 2
            disk:
              bus: virtio
            name: harddrive
          - bootOrder: 3
            cdrom:
              bus: sata
            name: virtiocontainerdisk
        machine:
          type: q35
        resources:
          requests:
            memory: 2G
      volumes:
      - name: cdromiso
        persistentVolumeClaim:
          claimName: win11
      - name: harddrive
        persistentVolumeClaim:
          claimName: winhd
      - containerDisk:
          image: quay.io/kubevirt/virtio-container-disk
        name: virtiocontainerdisk
EOF
```

```
virt-install    --name=guest-name    --network network=default    --disk path=win.img,size=8    --boot=cdrom    --cdrom=JZ_WIN10_X64_V2023.02.iso    --osinfo detect=on,name=win10    --graphics spice --ram=1024
```

## 参考
* [系统镜像](https://github.com/Tedezed/kubevirt-images-generator)
