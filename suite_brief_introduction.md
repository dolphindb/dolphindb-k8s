#  DolphinDB 套件简介

本文档介绍了如何创建一个简单的 Kubernetes 集群，部署 DolphinDB 套件，并使用 DolphinDB 套件部署 DolphinDB 集群。


<!-- TOC -->

- [快速上手 DolphinDB 套件](#快速上手-dolphindb-套件)
  - [1. DolphinDB 套件 简介](#1-dolphindb-套件-简介)
  - [2. 快速部署 DolphinDB](#2-快速部署-dolphindb)
    - [2.1 创建 Kubernetes 集群](#21-创建-kubernetes-集群)
    - [2.2 部署 DolphinDB 套件](#22-部署-dolphindb-套件)
      - [2.2.1 部署 Local Path Provisioner](#221-部署-local-path-provisioner)
      - [2.2.2 安装 DolphinDB 套件](#222-安装-dolphindb-套件)
    - [2.3 部署并连接 DolphinDB 集群](#23-部署并连接-dolphindb-集群)
      - [2.3.1 可视化界面](#231-可视化界面)
      - [2.3.2 部署 DolphinDB 集群](#232-部署-dolphindb-集群)
      - [2.3.3 访问 Grafana 面板](#233-访问-grafana-面板)
    - [2.4  升级 DolphinDB 集群](#24--升级-dolphindb-集群)
    - [2.5 销毁DolphinDB 集群和 Kubernetes 集群](#25-销毁dolphindb-集群和-kubernetes-集群)
    - [4. 探索更多](#4-探索更多)

<!-- /TOC -->
## 1. DolphinDB 套件 简介

DolphinDB 套件是指 Kubernetes 环境中 DolphinDB 的资源和界面管理组件的集合，包含以下部分：

- dolphindb-operator：DolphinDB 在 Kubernetes 环境中的资源管理器；

- dolphindb-webserver：DolphinDB 在 Kubernetes 环境中的可视化管理界面。

  > **警告** ！！！
  >
  > 本文中的部署说明仅用于测试目的，不要直接用于生产环境部署。

## 2. 快速部署 DolphinDB

**硬件环境**

| 硬件名称 | 配置信息                  |
| :------- | :------------------------ |
| 外网 IP  | 192.168.100.10            |
| 操作系统 | Linux（内核3.10以上版本） |
| 内存     | 500 GB                    |
| CPU      | x86_64（64核心）          |

**软件版本要求**

| 软件名称       | 版本                                                         |
| :------------- | :----------------------------------------------------------- |
| Docker         | Docker CE v20.10.12                                          |
| Kubectl        | 版本 >= 1.12                                                 |
| Helm           | v3.7.2                                                       |
| DolphinDB 套件 | [v1.0.0](https://hub.docker.com/r/dolphindb/dolphindb-webserver/tags)，正式版本号 |
| minikube       | 版本 1.0.0 及以上，推荐使用较新版本。                        |

本文介绍了如何创建一个 Kubernetes 集群，部署 DolphinDB 套件，并使用它部署一个3节点的高可用集群，最终搭建的集群节点如下:

```shell
controller1  => agent1 => 1 datanode
controller2  => agent2 => 1 datanode
controller3  => agent3 => 1 datanode
```

基本步骤如下：

1. 创建 Kubernetes 集群
2. 部署 DolphinDB 套件
3. 连接 DolphinDB 集群
4. 升级 DolphinDB 集群
5. 销毁 DolphinDB 集群

### 2.1 创建 Kubernetes 集群

创建集群之前，需要先搭建好 docker 以及 helm，kubectl 环境，参考: 

- [docker 安装教程](https://docs.docker.com/install/)
- [Helm 安装教程](https://helm.sh/docs/intro/install/)
- [kubectl 安装教程](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)

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
$ minikube start --force --driver=docker --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

> 中国大陆用户可以使用国内 gcr.io mirror 仓库，例如 `registry.cn-hangzhou.aliyuncs.com/google_containers`。

**使用 `kubectl` 进行集群操作**

可以使用 `minikube` 的子命令 `kubectl` 来进行集群操作。要使 `kubectl` 命令生效，需要在 shell 配置文件中添加以下别名设置命令，或者在打开一个新的 shell 后执行以下别名设置命令。

```bash
$ alias kubectl='minikube kubectl --'
```

执行以下命令检查集群状态，并确保可以通过 `kubectl` 访问集群:

```bash
$ kubectl cluster-info
```

期望输出:

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Kubernetes 集群部署完成，现在就可以开始部署 DolphinDB 套件了！

### 2.2 部署 DolphinDB 套件

   本节下面介绍部署步骤：

1. 部署[Local path provisioner](https://github.com/rancher/local-path-provisioner)；

> 注意：
> "Local path provisioner"只是提供了 storageclass ，用于创建 pvc ,如果用户使用其他类型的 sci ,则不需要部署,可以作为没有 sci 的用户的参考项


2. 部署 DolphinDB 套件。

#### 2.2.1 部署 Local Path Provisioner

Local Path Povisioner 可以在 Kubernetes 环境中作为本机路径的 CSI ，使用节点的本机路径来动态分配持久化存储。本节将介绍具体实现方法。

• 从 github 上下载 local-path-provisioner 安装文件：

```shell
$ wget https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

  期望输出

```bash
--2022-01-12 12:05:27--  https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml                              
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.108.133, 185.199.110.133, 185.199.109.133, ...                
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.108.133|:443... connected.          
HTTP request sent, awaiting response... 200 OK                          
Length: 3451 (3.4K) [text/plain]                                         
Saving to: ‘local-path-storage.yaml’                                     
100%[=================================================================================================================================================================================================>] 3,451        402B/s   in 8.6s                                                               
2022-01-12 12:09:35 (402 B/s) - ‘local-path-storage.yaml’ saved [3451/3451]
```

• 修改配置：

![image-20220112121713686](./images/k8s_deployment/k8s-deployment-1.png)

该路径目的是持久过存储容器中的数据（详细介绍参考 [local-path-provisioner配置](https://github.com/rancher/local-path-provisioner#configuration) ）

> **注意**：
>
> 修改分配 PV 的本机路径：
> 找到名为 "local-path-config" 的 ConfigMap 资源，其 data 字段下的 "config.json" 里包含的属性 "paths" 即为分配的 K8S 集群中的节点路径。如果配置了多个节点路径，将随机选取其中一个作为 PV。

• 在 Kubernetes 环境中部署：

```shell
$ kubectl apply -f  local-path-storage.yaml
```

 期望输出

```shell
namespace/local-path-storage created
serviceaccount/local-path-provisioner-service-account created
clusterrole.rbac.authorization.k8s.io/local-path-provisioner-role created
clusterrolebinding.rbac.authorization.k8s.io/local-path-provisioner-bind created
deployment.apps/local-path-provisioner created
storageclass.storage.k8s.io/local-path created
configmap/local-path-config created
```

#### 2.2.2 安装 DolphinDB 套件

DolphinDB 套件集成在名为 "dolphidb-mgr" 的 chart 包中，存储在 Helm 仓库中。通过 Helm 工具进行部署：

1. 添加 DolphinDB 仓库

```shell
$ helm repo add dolphindb https://dolphindbit.github.io/helm-chart/
```

期望输出：

```
"dolphindb" has been added to your repositories
```

2. 安装 DolphinDB 套件

```shell
$ helm -n dolphindb install dolphindb-mgr dolphindb/dolphindb-mgr --set global.version=v1.0.1 \
       --set grafana.service.type=NodePort,prometheus.server.service.type=NodePort\
       --set dolphindb-webserver.nodePortIP="192.168.100.10" --set global.storageClass=local-path\
       --set-file license.content=./dolphindb.lic --create-namespace
```

DolphinDB 的进程启动需要 license 才能生效，所以需要在指令中增加 `license.content=./license.lic` ，并将其改为license 所在的路径。

期望输出：

```shell
NAME: dolphindb-mgr                                                     
LAST DEPLOYED: Wed Jan 12 14:39:11 2022                                 
NAMESPACE: dolphindb
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

主要参数说明如下：

- `-ndolphindb --create-namespace`：将 DolphinDB 套件部署在名为`dolphindb`的 namespace 中，如果名为`dolphindb` 的 namespace 不存在，则创建
- `$licensePath`：DolphinDB License 的存放的绝对路径
- `grafana.service.type=NodePort,prometheus.server.service.type=NodePort`: grafana 与 prometheus在 Kubernetes 环境中提供的服务类型。
- `global.serviceType=NodePort, dolphindb-webserver.nodePortIP`：DolphinDB 套件在 Kubernetes 环境中提供的服务类型。ClusterIP：仅在 Kubernetes 环境内部访问；NodePort：通过主机端口可在 Kubernetes 环境内/外部访问；LoadBalancer：通过 Kubernetes 环境中的负载均衡供 Kubernetes 环境内/外部访问
- `global.version`: DolphinDB 套件版本号为 [`v1.0.1`](https://hub.docker.com/r/dolphindb/dolphindb-operator/tags)，相关 Release 说明见 [DolphinDB in Kubernetes 发行说明](https://dolphindb.net/dolphindb/dolphindb_k8s/-/blob/master/release/1.0/README_CN.md)。
- `global.storageClass`: DolphinDB 使用的持久化存储的存储类，不指定则使用默认存储类。

> 注意：
>
> DolphinDB License 必须是官方授权可用的。若使用无效的 license，会出现诸如 "persistentvolumeclaim log-ddb-t3-crt-0-0 not found" 的报错。

1. 查看 DolphinDB 套件部署情况

```shell
$ kubectl get pods -ndolphindb
```

期望输出：

```shell
NAME                                   	   		  READY   STATUS    RESTARTS   AGE                                                         
dolphindb-operator-0                        	  1/1     Running   0          20m                                                         
dolphindb-operator-1                   			  1/1     Running   0          12m                                                         
dolphindb-webserver-5487785cfd-msr5w   			  1/1     Running   0          20m                                                         
dolphindb-webserver-5487785cfd-ns5dq   			  1/1     Running   0          20m
dolphindb-mgr-grafana-759dccc7d4-cskx6            1/1     Running   0          8m17s
dolphindb-mgr-prometheus-server-7657fdd64-2lkcr   1/1     Running   0          8m17s
```

当所有的 pods 都处于 Running 状态时，继续下一步。

### 2.3 部署并连接 DolphinDB 集群

#### 2.3.1 可视化界面

**转发 DolphinDB webServer 服务 8080 端口**

DolphinDB 套件提供的可视化界面默认使用 NodePort 的 ServiceType 进行服务暴露。在完成 DolphinDB 套件部署之后，本步骤先将端口从本地主机转发到 Kubernetes 中的 DolphinDB webServer的 **Servcie**。

可在 Kubernetes 环境中查看可视化界面对应的 Service，

```shell
$ kubectl -ndolphindb get svc | grep dolphindb-webserver

#输出结果
dolphindb-webserver   NodePort    10.109.94.68    <none>        8080:30908/TCP   43m
```

然后，使用以下命令转发本地端口到集群：

```
kubectl port-forward --address 0.0.0.0 -n dolphindb svc/dolphindb-webserver 8080:8080 > pf8000.out &
```

如果端口 `8000` 已经被占用，可以更换一个空闲端口。命令会在后台运行，并将输出转发到文件 `pf8000.out`。所以，你可以继续在当前 shell 会话中执行命令。

**连接 DolphinDB webServer 服务**

通过浏览器访问 DolphinDB 套件的可视化界面：

```
http://$IP:$Port/dolphindb-cloud
```

参数说明如下：

- $IP：Kubernetes 环境中主机 的 ip。

- $Port：转发到主机的端口（输出结果中的"8080"）。

本教程即http://192.168.100.10:8080/dolphindb-cloud/

#### 2.3.2 部署 DolphinDB 集群

1. 点击新建集群

![image-20220112155415310](./images/k8s_deployment/k8s-deployment-2.png)

2. 选择新建集群的配置

![image-20220112155429794](./images/k8s_deployment/k8s-deployment-3.png)

> 注意：
>
> 1、控制节点与数据节点的 CPU、内存等资源不能超过服务器本身资源，否则集群状态会有异常。
>
> 2、日志模式有两种分别为标准输出和输出到文件，输出到文件性能更佳（推荐）。
>
> 3、控制节点副本数以及数据节点副本数指的集群的控制节点与数据节点的数量。
>
> 4、标准 pvc 更加灵活，local path 更加简便（推荐，部署文档中的 local-path 是存储类，也是用于提供 pvc 的）。
>
> 5、端口指的是 container 的端口，用在 LoadBalancer 中，指定 port 。

3. 成功部署集群

![image-20220112161319747](./images/k8s_deployment/k8s-deployment-4.png)

- 状态变成 `Available`，表示集群创建成功，可以正常提供服务。

4. 连接 DolphinDB 集群

![image-20220112171813273](./images/k8s_deployment/k8s-deployment-5.png)

如图所示，控制节点的 IP 和 PORT 为 `192.168.100.10:31598`，数据节点的 IP 和 PORT 为 `192.168.100.10:31236`。

**转发 DolphinDB Controller 以及 Datanode 服务**

查看 Controller 以及 Datanode 端口

```
ddb-test-ctr                      NodePort    10.109.51.110    <none>        31210:30733/TCP                                 20m
ddb-test-ctr-inner                ClusterIP   10.108.154.6     <none>        31210/TCP                                       20m
ddb-test-dn                       NodePort    10.96.242.219    <none>        8960:31592/TCP,32210:32508/TCP,8000:31366/TCP   20m
```

转发服务

```bash
kubectl port-forward --address 0.0.0.0 -n dolphindb svc/ddb-test-ctr 31598:31210 > pf31598.out &
kubectl port-forward --address 0.0.0.0 -n dolphindb svc/ddb-test-ctr 31236:31210 > pf31598.out &
```

> 注意：
>
> 目前 NodePort 服务类型的端口随机分配，不支持指定。

#### 2.3.3 访问 Grafana 面板

你可以访问 Grafana 服务端口，以便本地访问 Grafana 面板

```
kubectl get svc -ndolphindb|grep grafana
```

你可以转发 Grafana 服务端口，以便本地访问 Grafana 面板。

```
kubectl port-forward --address 0.0.0.0 -n dolphindb svc/dolphindb-mgr-grafana-759dccc7d4-nkhhk 3000:80 > pf80.out &
```

Grafana 面板可在 kubectl 所运行的主机上通过 http://NodeIP:NodePort 访问。默认用户名和密码都是 "admin" 

了解更多使用 DolphinDB 套件部署 DolphinDB 集群监控的信息，可以查阅 [DolphinDB 集群监控与告警](https://dolphindb.net/dolphindb/dolphindb_k8s/-/blob/master/Monitoring_and_alerting_in_k8s.md)。

### 2.4  升级 DolphinDB 集群

DolphinDB 组件可简化 DolphinDB 集群的滚动升级。

执行以下命令，手动修改 version 字段为 1.30.15 可将 DolphinDB 集群升级到 1.30.15 版本：

```shell
$ kubectl edit ddb -ndolphindb
```

![image-20220112180135714](./images/k8s_deployment/k8s-deployment-6.png)

如下图所示，version 变成 `1.30.15` 以及 status 变成 Available 状态

![image-20220112180645872](./images/k8s_deployment/k8s-deployment-7.png)

> 注意：
>
> 通过 web 升级 DolphinDB 的接口正在开发中。

### 2.5 销毁DolphinDB 集群和 Kubernetes 集群

完成测试后，你可能希望销毁 TiDB 集群和 Kubernetes 集群。

**停止 kubectl 的端口转发**

如果你仍在运行正在转发端口的 `kubectl` 进程，请终止它们：

```bash
$ pgrep -lfa kubectl
```

**销毁 DolphinDB 集群**

​    方式一：通过 Web 管理器删除按钮销毁

![image-20220113100852771](./images/k8s_deployment/k8s-deployment-8.png)

​    方式二：通过命令行进行销毁

```shell
$ kubectl delete ddb $ddbName  -ndolphindb
```

参数说明如下：

- $ddbName：Kubernetes 环境中删除的 DolphinDB 集群名称。

**卸载 DolphinDB 套件**

通过以下命令可卸载 DolphinDB 套件

```bash
$ helm uninstall dolphindb-mgr-ndolphindb
```

**销毁 Kuberbetes 集群**

销毁 Kubernetes 集群的方法取决于其创建方式。以下是销毁 Kubernetes 集群的步骤。

如果使用了 minikube 创建 Kubernetes 集群，测试完成后，执行下面命令来销毁集群：

```bash
minikube delete --all
```

### 4. 探索更多

- [DolphinDB 套件简介](./suite_brief_introduction.md)
- [自建 Kubernetes 集群](./k8s_deployment.md)
- 云厂商
  - [Aliyun](./k8s_deployment_in_Aliyun.md)
  - [AWS](./k8s_deployment_in_AWS.md)