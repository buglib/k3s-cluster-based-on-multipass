#!/bin/bash

# 先删除旧的集群
multipass delete master worker1 worker2
multipass purge

# 创建三个节点
# multipass launch --name master --memory 1G --disk 5G 20.04 $mount
# multipass launch --name worker1 --memory 1G --disk 5G 20.04 $mount
# multipass launch --name worker2 --memory 1G --disk 5G 20.04 $mount

src=$1
dst=$2
mount=""
if [[ $src != "" && $dst != "" ]]; then
    mount="--mount $src:$dst"
else
    mount=""
fi

for host in "master" "worker1" "worker2"
do
    multipass launch --name $host --memory 1G --disk 5G 20.04 $mount
done

# 接着在各个节点上安装k3s
multipass exec master -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -"
master_url=https://`multipass info master | grep IPv4 | awk '{print $2}'`:6443
token=`multipass exec master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token"`
multipass exec worker1 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"
multipass exec worker2 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"

# 然后在三个节点上安装docker
# 1. 现修改apt源
# 2. sudo apt update && sudo apt install -y docker.io
multipass exec master -- /bin/bash -c "sudo apt update && sudo apt install -y docker.io"
multipass exec worker1 -- /bin/bash -c "sudo apt update && sudo apt install -y docker.io"
multipass exec worker2 -- /bin/bash -c "sudo apt update && sudo apt install -y docker.io"
# 最后，将docker镜像仓库切换为国内的
docker_config_file=/etc/docker/daemon.json
mkdir -p $docker_config_file
multipass exec master -- /bin/bash -c "sudo touch ${docker_config_file} && sudo chmod 666 ${docker_config_file} && cat >> ${docker_config_file} <<EOF
{
    "registry-mirrors": [
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF"

multipass exec worker1 -- /bin/bash -c "sudo touch ${docker_config_file} && sudo chmod 666 ${docker_config_file} && cat >> ${docker_config_file} <<EOF
{
    "registry-mirrors": [
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF"

multipass exec worker2 -- /bin/bash -c "sudo touch ${docker_config_file} && sudo chmod 666 ${docker_config_file} && cat >> ${docker_config_file} <<EOF
{
    "registry-mirrors": [
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF"