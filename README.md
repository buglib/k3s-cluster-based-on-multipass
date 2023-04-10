# k3s-cluster-based-on-multipass：基于Multipass创建K3S集群

## 1. 使用multipass创建三个节点，配置如下：
| host name | CPU core number | Memory size | disk size |
| --------- | --------------- | ----------- | --------- |
| master    | 1               | 1G          | 5G        |
| worker1   | 1               | 1G          | 5G        |
| worker2   | 1               | 1G          | 5G        |

```
multipass launch --name master --memory 1G --disk 5G 20.04
multipass launch --name worker1 --memory 1G --disk 5G 20.04
multipass launch --name worker2 --memory 1G --disk 5G 20.04
```

## 2. 在master节点上安装k3s组件
### 2.1 参考文章

- [快速入门指南](https://docs.rancher.cn/docs/k3s/quick-start/_index)
- [教你用multipass快速搭建k8s集群](https://www.cnblogs.com/chenqionghe/p/15227277.html)

### 2.2 运行中文官网提供的安装脚本
```
multipass exec master -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -"
```

接着保存master的IP地址，用于将worker节点加入集群
```
master_url=https://`multipass info master | grep IPv4 | awk '{print $2}'`:6443
```

然后保存master的token，同样用于将worker节点加入集群
```
token=`multipass exec master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token"`
```

### 2.3 在两个worker节点上安装k3s组件
```
# 安装worker1
multipass exec worker1 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"

# 安装worker2
multipass exec worker2 -- /bin/bash -c "curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=${master_url} K3S_TOKEN=${token} sh -"
```

## 3. 在各个节点上检查一下k3s是否安装成功
```
# 检查master
systemctl status k3s

# 在worker1和worker2上检查
systemctl status k3s-agent
```