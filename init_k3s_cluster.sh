#!/bin/bash

# 先创建三个节点
multipass launch --name master --memory 1G --disk 3G 20.04
multipass launch --name worker1 --memory 1G --disk 3G 20.04
multipass launch --name worker2 --memory 1G --disk 3G 20.04

# 接着在各个节点上安装k3s
multipass exec master -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -"
master_url=https://`multipass info master | grep IPv4 | awk '{print $2}'`:6443
token=`multipass exec master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token"`
multipass exec worker1 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"
multipass exec worker2 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"