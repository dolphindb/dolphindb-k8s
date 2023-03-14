#  快速上手 DolphinDB 套件

本文档介绍了如何创建一个简单的 Kubernetes 集群，部署 DolphinDB 套件，并使用 DolphinDB 套件部署 DolphinDB 集群。


<!-- TOC -->

- [快速上手 DolphinDB 套件](#快速上手-dolphindb-套件)
  - [1. DolphinDB 套件 简介](#1-dolphindb-套件-简介)
  - [2. 快速部署 DolphinDB](#2-快速部署-dolphindb)
    - [2.1 创建 Kubernetes 集群](#21-创建-kubernetes-集群)
    - [2.2 部署 DolphinDB 套件](#22-部署-dolphindb-套件)
      - [2.2.1 部署 Local Path Provisioner](#221-部署-local-path-provisioner)
      - [2.2.2 安装 DolphinDB 套件](#222-安装-dolphindb-套件)
    - [2.3 管理 DolphinDB 集群](#23-管理-dolphindb-集群)
    - [2.4 卸载 DolphinDB 套件](#24-卸载-dolphindb-套件)
    - [2.5 销毁 Kubernetes 集群](#25-销毁-kuberbetes-集群)
  - [3. 常见问题及解决方案](#3-常见问题及解决方案)
  - [4. 探索更多](#4-探索更多)

<!-- /TOC -->
## 1. DolphinDB 套件 简介

DolphinDB 套件是指 Kubernetes 环境中 DolphinDB 的资源和界面管理组件的集合，包含以下部分：

- dolphindb-operator：DolphinDB 在 Kubernetes 环境中的资源管理器；
- dolphindb-cloud-portal：DolphinDB 在 Kubernetes 环境中的可视化管理界面。
- dollphindb-webserver: DolphinDB-Webserver 为 dolphindb-cloud-portal 提供调用接口。
- alertmanager: Alertmanager 处理客户端应用程序(如 Prometheus 服务器)发送的警报。它负责将报警内容去重，分组并将告警内容路由到合适的接收器中。
- grafana: Grafana 用于实现监控数据的可视化。
- loki: Loki 是一个水平可扩展，高可用性，多租户的日志聚合系统。
- node-exporter: Node-Exporter 为 Prometheus 采集硬件和系统内核相关的指标。
- prometheus: ​Prometheus 是以开源软件的形式进行研发的系统监控和告警工具包。

  > 警告 ！！！
  >
  > 本文中的部署说明仅用于测试目的，不要直接用于生产环境部署。

## 2. 快速部署 DolphinDB

**硬件环境**

| 硬件名称 | 配置信息                  |
| :------- | :------------------------ |
| 外网 IP  | 10.0.0.82                 |
| 操作系统 | Linux（内核版本3.10以上） |
| 内存     | 500 GB                    |
| CPU      | x86_64（64核心）          |

**软件版本要求**

| 软件名称       | 版本                                                         |
| :------------- | :----------------------------------------------------------- |
| Docker         | Docker CE v20.10.12                                          |
| Kubectl        | v1.22.3（版本必须在1.24以下）                                |
| Helm           | v3.7.2                                                       |
| DolphinDB 套件 | [v1.0.3](https://hub.docker.com/r/dolphindb/dolphindb-webserver/tags)，正式版本号 |
| minikube       | 版本 1.0.0 及以上，推荐使用较新版本。                        |

本文介绍了如何创建一个 Kubernetes 集群，部署 DolphinDB 套件，并使用它部署一个3节点的高可用集群，最终搭建的集群节点如下:

```shell
controller1  => agent1 => 1 datanode => 1 Computenode
controller2  => agent2 => 1 datanode => 1 Computenode
controller3  => agent3 => 1 datanode => 1 Computenode
```

基本步骤如下：

1. 创建 Kubernetes 集群
2. 部署 DolphinDB 套件
3. 管理 DolphinDB 集群
4. 卸载 DolphinDB 套件
5. 销毁 Kuberbetes 集群

### 2.1 创建 Kubernetes 集群

创建集群之前，需要先搭建好 docker 以及 helm，kubectl 环境，参考: [docker 安装教程](https://docs.docker.com/install/)，[Helm 安装教程](https://helm.sh/docs/intro/install/)，[kubectl 安装教程](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)。

docker, helm, kubectl 安装完成后，在 Linux 命令行窗口执行以下命令，若显示 docker,helm, kubectl 版本号，则说明安装成功。

```bash
$ docker -v
$ helm version
$ kubectl version
```

本节介绍了一种创建 Kubernetes 测试集群的方法，可用于测试 DolphinDB 套件管理的 DolphinDB 集群。

- [使用 minikube](https://docs.pingcap.com/zh/tidb-in-kubernetes/stable/get-started#使用-minikube-创建-kubernetes-集群) 创建在虚拟机中运行的 Kubernetes

**使用 minikube start 启动 Kubernetes 集群**

安装完 minikube 后，可以执行下面命令启动 Kubernetes 集群：

```bash
$ minikube start --vm-driver=none --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

> 中国大陆用户可以使用国内 gcr.io mirror 仓库，例如 `registry.cn-hangzhou.aliyuncs.com/google_containers`。

**使用 `kubectl` 进行集群操作**

你可以使用 `minikube` 的子命令 `kubectl` 来进行集群操作。要使 `kubectl` 命令生效，你需要在 shell 配置文件中添加以下别名设置命令，或者在打开一个新的 shell 后执行以下别名设置命令。

```bash
$ alias kubectl='minikube kubectl --'
```

执行以下命令检查集群状态，并确保可以通过 `kubectl` 访问集群:

```bash
$ kubectl cluster-info
```

期望输出:

```
Kubernetes control plane is running at https://10.0.2.15:8443
CoreDNS is running at https://10.0.2.15:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Kubernetes 集群部署完成，现在就可以开始部署 DolphinDB 套件了！

### 2.2 部署 DolphinDB 套件

   本节下面介绍部署步骤：

1. 部署[Local path provisioner](https://github.com/rancher/local-path-provisioner)；

> 注意：
> "Local path provisioner" 只是提供了 storageclass，用于创建 pvc，如果用户使用其他类型的 sci，则不需要部署，可以作为没有 sci 的用户的参考项。


2. 部署 DolphinDB 套件。

#### 2.2.1 部署 Local Path Provisioner

部署 Local Path Provisioner可以参考[文档](./k8s_deployment.md#221-部署-local-path-provisioner)

#### 2.2.2 安装 DolphinDB 套件

安装 DolphinDB 套件可以参考[文档](./k8s_deployment.md#222-安装-dolphindb-套件)

### 2.3 管理 DolphinDB 集群

通过 DolphinDB 套件管理 DolphinDB 集群可以参考[文档](./dolphindb_cloud_portal.md)。

### 2.4 卸载 DolphinDB 套件

通过以下命令可卸载 DolphinDB 套件

```bash
$ helm uninstall dolphindb-mgr -n dolphindb
```

### 2.5 销毁 Kuberbetes 集群

销毁 Kubernetes 集群的方法取决于其创建方式。以下是销毁 Kubernetes 集群的步骤。

如果使用了 minikube 创建 Kubernetes 集群，测试完成后，执行下面命令来销毁集群：

```bash
minikube delete --all
```

## 3. 常见问题及解决方案

- 在执行`minikube start --vm-driver=none --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`后无法成功启动集群且报错如下：

  ```shell
  [ERROR CRI]: container runtime is not running: output:
  ```

  解决方案：

  更换kubectl版本，要保证kubectl版本在1.24以下。

- 在执行`kubectl port-forward --address 0.0.0.0 -n dolphindb svc/dolphindb-webserver 8080:8080 > pf8000.out &`端口转发命令并通过浏览器访问可视化监控界面后，主机命令行交互界面出现如下报错：

  ```shell
  E0823 21:29:22.628022   89708 portforward.go:400] an error occurred forwarding 8080 -> 8080: error forwarding port 8080 to pod 470dbdeb590bde40397e582226b5889a63ac380c1e6970cc2ae9046e6e485917, uid : unable to do port forwarding: socat not found
  ```

  解决方案：

  以centos7系统为例，执行`yum install socat`命令安装socat，其它版本诸如Ubuntu可以采用其它安装方法安装socat。

## 4. 探索更多

如果你想在生产环境部署，请参考以下文档：

在公有云上部署：

自托管 Kubernetes 集群：