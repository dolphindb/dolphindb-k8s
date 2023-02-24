# 通过 DolphinDB CR 在 Kubernetes 上管理 DolphinDB 集群

- [通过 DolphinDB CR 在 Kubernetes 上管理 DolphinDB 集群](#通过-dolphindb-cr-在-kubernetes-上管理-dolphindb-集群)
  - [1. 概述](#1-概述)
  - [2. 创建 DolphinDB 集群](#2-创建-dolphindb-集群)
    - [2.1. 前置条件](#21-前置条件)
  - [3. 创建单节点 DolphinDB](#3-创建单节点-dolphindb)
  - [4. 创建单控制节点 DolphinDB 集群](#4-创建单控制节点-dolphindb-集群)
  - [5. 创建多控制节点 DolphinDB 集群](#5-创建多控制节点-dolphindb-集群)
  - [6. 更新 DolphinDB 集群](#6-更新-dolphindb-集群)
  - [7. 删除 DolphinDB 集群](#7-删除-dolphindb-集群)
  - [8. CRD 说明](#8-crd-说明)
    - [8.1. DolphinDB CRD](#81-dolphindb-crd)
    - [8.2. InstanceMeta](#82-instancemeta)
  - [9. 常见问题](#9-常见问题)

本文介绍如何使用 `DolphinDB CR (Customer Resources)` 在 Kubernetes 上创建和管理 DolphinDB 集群。如需更简易地管理集群，可以使用 DolphinDB 套件提供的可视化管理页面。

以下说明与使用基于 v1.1.1 版本的 DolphinDB CR, 不同版本的 CR 之间可能存在部分差异。


##  1. <a name=''></a>概述

`DolphinDB-Operator` 作为一种特定于应用的控制器，可扩展 Kubernetes API 的功能，来代表 Kubernetes 用户创建、配置和管理复杂应用的实例。它在基本 Kubernetes 资源和控制器概念之上构建，又涵盖了特定于域或应用的知识，用于实现其所管理软件的整个生命周期的自动化。用户可以通过安装 DolphinDB [套件](https://github.com/dolphindb/dolphindb-k8s/blob/master/deploy_k8s_quickly.md) 实现 Dolphindb-Opeartor 的部署。在创建、更新或删除 DolphinDB CR 时，会触发 `Dolphindb-Opeartor` 的调谐逻辑，从而根据用户操作管理 DolphinDB 集群，同时 `Dolphindb-Opeartor` 也会根据集群的状态来更新 `DolphinDB CR` 的状态。

##  2. <a name='DolphinDB'></a>创建 DolphinDB 集群

###  2.1. <a name='-1'></a>前置条件

在使用 `DolphinDB CR` 之前，需要先安装 DolphinDB [套件](https://github.com/dolphindb/dolphindb-k8s/blob/master/deploy_k8s_quickly.md)。

下面，我们通过三个简单示例来介绍如何通过 `DolphinDB CR` 创建 DolphinDB 集群。

##  3. <a name='DolphinDB-1'></a>创建单节点 DolphinDB

首先，参考以下单节点 *.yaml* 配置文件，准备一个用于部署的 CR 文件：

```yaml
$ cat <<EOF > standalone.yaml
apiVersion: dolphindb.dolphindb.io/v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  mode: standalone
  datanode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 1
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  disableExporter: false
  disablePromtail: false
  licenseServerAddress: None
  logCleanLimit: "0.9"
  minPersistentVolumeSize: "0"
  storageClassName: standard
  timeMeta:
    localTimeFileHostPath: /etc/localtime
    localTimeFileMountPath: /etc/localtime
  version: v2.00.7
EOF
```

然后，部署该 CR 文件:

```
$ kubectl apply -f standalone.yaml
```

使用以下命令查看 `pod` 的启动情况：

```
$ kubectl get po -n dolphindb
NAME                         READY     STATUS    RESTARTS    AGE
ddb-test-dn-0-0               4/4     Running      0         1h
```

集群正常启动后，使用以下命令查看 `Service` 暴露的端口，通过这些端口可以连接到 DolphinDB 对应节点：

```
$ kubectl get svc -n dolphindb
NAME                               TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
ddb-test-dn                       NodePort    10.110.231.114      <none>    32210:30074/TCP,8000:32153/TCP   1h
```

##  4. <a name='DolphinDB-1'></a>创建单控制节点 DolphinDB 集群

首先，参考以下单机 *.yaml* 配置文件，准备一个用于部署的 CR 文件：

```yaml
$ cat <<EOF > singlecontroller.yaml
apiVersion: dolphindb.dolphindb.io/v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  clusterType: singlecontroller
  computenode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  controller:
    dataSize: 1Gi
    logSize: 1Gi
    port: 31210
    replicas: 1
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  customMeta: {}
  datanode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  disableExporter: false
  disablePromtail: false
  licenseServerAddress: None
  logCleanLimit: "0.9"
  minPersistentVolumeSize: "0"
  mode: cluster
  storageClassName: standard
  timeMeta:
    localTimeFileHostPath: /etc/localtime
    localTimeFileMountPath: /etc/localtime
  version: v2.00.7
EOF
```

然后，部署该 CR 文件:

```
$ kubectl apply -f singlecontroller.yaml
```

使用以下命令查看 `pod` 的启动情况：

```
$ kubectl get po -n dolphindb
NAME                                            READY     STATUS    RESTARTS      AGE
ddb-test-cn-0-0                                   4/4     Running      0          1h
ddb-test-cn-1-0                                   4/4     Running      0          1h
ddb-test-ctr-0-0                                  4/4     Running      0          1h
ddb-test-dn-0-0                                   4/4     Running      0          1h
ddb-test-dn-1-0                                   4/4     Running      0          1h
```

集群正常启动后，使用以下命令可以查看 `Service` 暴露的端口，通过这些端口可以连接到 DolphinDB 对应节点：

```
$ kubectl get svc -n dolphindb
NAME                               TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
ddb-test-cn                       NodePort    10.100.19.169       <none>    32210:31094/TCP,8000:30623/TCP   1h
ddb-test-ctr                      NodePort    10.99.17.228        <none>    31210:30018/TCP                  1h
ddb-test-ctr-inner                ClusterIP   10.102.47.245       <none>    31210/TCP                        1h
ddb-test-dn                       NodePort    10.110.231.114      <none>    32210:30074/TCP,80               1h
```

##  5. <a name='DolphinDB-1'></a>创建多控制节点 DolphinDB 集群

首先，参考以下多节点控制器的 *.yaml* 控制文件，准备一个部署 CR 文件：

```yaml
$ cat <<EOF > multicontroller.yaml
apiVersion: dolphindb.dolphindb.io/v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  clusterType: multicontroller
  computenode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  controller:
    dataSize: 1Gi
    logSize: 1Gi
    port: 31210
    replicas: 3
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  customMeta: {}
  datanode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  disableExporter: false
  disablePromtail: false
  licenseServerAddress: None
  logCleanLimit: "0.9"
  minPersistentVolumeSize: "0"
  mode: cluster
  storageClassName: standard
  timeMeta:
    localTimeFileHostPath: /etc/localtime
    localTimeFileMountPath: /etc/localtime
  version: v2.00.7
EOF
```

然后，部署该 CR 文件:

```
$ kubectl apply -f multicontroller.yaml
```

使用以下命令查看 `pod` 的启动情况：

```
$ kubectl get po -n dolphindb
NAME                              READY     STATUS    RESTARTS      AGE
ddb-test-cn-0-0                    4/4     Running      0          1h
ddb-test-cn-1-0                    4/4     Running      0          1h
ddb-test-ctr-0-0                   4/4     Running      0          1h
ddb-test-ctr-1-0                   4/4     Running      0          1h
ddb-test-ctr-2-0                   4/4     Running      0          1h
ddb-test-dn-0-0                    4/4     Running      0          1h
ddb-test-dn-1-0                    4/4     Running      0          1h
ddb-test6-svc-mgr-89666f687-8bk2j  1/1     Running      0          1h
```

集群正常启动后，使用以下命令查看 `Service` 暴露的端口，通过这些端口可以连接到 DolphinDB 对应节点：

```
$ kubectl get svc -n dolphindb
NAME                               TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
ddb-test-cn                       NodePort    10.100.19.169       <none>    32210:31094/TCP,8000:30623/TCP   1h
ddb-test-ctr                      NodePort    10.99.17.228        <none>    31210:30018/TCP                  1h
ddb-test-ctr-inner                ClusterIP   10.102.47.245       <none>    31210/TCP                        1h
ddb-test-dn                       NodePort    10.110.231.114      <none>    32210:30074/TCP,80               1h
```

##  6. <a name='DolphinDB-1'></a>更新 DolphinDB 集群

如需更新 DolphinDB 集群，可以直接修改 DolphinDB CR：

```yaml
$ kubectl edit ddb -n dolphindb test
apiVersion: dolphindb.dolphindb.io/v1
kind: DolphinDB
metadata:
  creationTimestamp: "2023-01-12T08:08:39Z"
  generation: 6
  name: test
  namespace: dolphindb
  resourceVersion: "41334326"
  uid: 54132012-e461-4f21-8ab2-83c522071ac4
spec:
  clusterType: singlecontroller
  computenode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: "0"
        memory: "0"
  controller:
    clusterConfig:
      OLAPCacheEngineSize: "2"
    controllerConfig:
      dfsRecoveryWaitTime: "1000"
    dataSize: 1Gi
    logSize: 1Gi
    port: 31210
    replicas: 1
    resources:
      limits:
        cpu: "2"
        memory: 1Gi
      requests:
        cpu: "1"
        memory: "0"
  customMeta: {}
  datanode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 2
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: "0"
        memory: "0"
  disableExporter: false
  disablePromtail: false
  licenseServerAddress: None
  logCleanLimit: "0.9"
  minPersistentVolumeSize: "0"
  mode: cluster
  storageClassName: standard
  timeMeta:
    localTimeFileHostPath: /etc/localtime
    localTimeFileMountPath: /etc/localtime
  version: v2.00.7
status:
  computenodeStatus:
    currentReplicas: 2
    instanceStatus:
      ddb-test-cn-0:
        phase: Ready
      ddb-test-cn-1:
        phase: Ready
    phase: Ready
    readyReplicas: 2
    replicas: 2
  controllerStatus:
    currentReplicas: 1
    instanceStatus:
      ddb-test-ctr-0:
        phase: Ready
    phase: Ready
    readyReplicas: 1
    replicas: 1
  datanodeStatus:
    currentReplicas: 2
    instanceStatus:
      ddb-test-dn-0:
        phase: Ready
      ddb-test-dn-1:
        phase: Ready
    phase: Ready
    readyReplicas: 2
    replicas: 2
  phase: Available
```

如需升级 DolphinDB 集群的版本到 v2.00.8，可将 CR 中的 version: v2.00.7 修改为 version: v2.00.8。修改完后保存退出，此时 DolphinDB 集群会重启。

使用以下命令查看集群 `pod` 启动情况：

```
$ kubectl get po -n dolphindb
NAME                                                   READY   STATUS              RESTARTS   AGE
ddb-test-cn-0-0                                         0/4     Init:0/1               0      6s
ddb-test-cn-1-0                                         0/4     Init:0/1               0      6s
ddb-test-config-refresher-d4zdz                         0/1     ContainerCreating      0      6s
ddb-test-ctr-0-0                                        0/4     Init:0/1               0      5s
ddb-test-dn-0-0                                         0/4     Init:0/1               0      6s
ddb-test-dn-1-0                                         0/4     Init:0/1               0      6s
```

当 `pod` 状态均为 `Running` 时，说明集群更新成功。

##  7. <a name='DolphinDB-1'></a>删除 DolphinDB 集群

可以使用下面指令删除 DolphinDB 集群。

> :exclamation: 数据库中存储的数据也会被删除，请谨慎操作。

```
$ kubectl delete ddb -n dolphindb test
```

##  8. <a name='CRD'></a>CRD 说明

###  8.1. <a name='DolphinDBCRD'></a>DolphinDB CRD

- `apiVersion`:  `dolphindb.dolphindb.io/v1`
- `kind`: `DolphinDB`
- `metadata`:
  - `name`: `string`, `DolphinDB` 集群名称
  - `namespace`: `string`，`DolphinDB` 集群所在命名空间
- `spec`:
  - `mode`: `string`，部署模式，可选值为 `cluster`(集群模式) 或者 `standalone`(单机默认)
  - `clusterType`: `string`，集群类型，可选值为 `singlecontroller`(单控制节点) 或者 `multicontroller`(多控制节点)
  - `version`: `string`，`DolphinDB` 版本，根据已发布 `DolphinDB` 版本进行选择
  - `storageClassName`: `string`，存储卷的类型
  - `licenseServerAddress`: `string`，证书服务地址
  - `logMode`: `int`，日志输出模式，0(输出到文件)，1(输出到控制台) 或 2(同时输出到文件和控制台)
  - `logCleanLimit`: `string`，日志清理阈值，如: 0.9
  - `disableCoreDump`: `bool`, 是否关闭核心转储功能
  - `disablePromtail`: `bool`，是否关闭 `promtail` 功能
  - `disableExporter`: `bool`，是否关闭 `exporter` 功能
  - `minPersistentVolumeSize`: `string`，最小存储卷大小
  - `controller`: 控制节点配置
    - `replicas`: `int`，控制节点实例数
    - `port`: `int`，控制节点端口
    - `logSize`: `string`，日志存储空间大小，如：1Gi
    - `dataSize`: `string`，数据存储空间大小，如: 1Gi
    - `resources`: 资源配额
      - `limits`: 最大限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: `string`，内存资源配置，如: 1Gi
      - `requests`: 最小限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: `string`，内存资源配置，如: 1Gi
    - `instances`: map[int]InstanceMeta，节点实例配置
    - `volumes`: [][Volume](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，需要挂载的存储卷配置
    - `volumeMounts`: [][VolumeMount](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，存储卷挂载路径配置
    - `clusterConfig`: map[string]string，集群配置
    - `controllerConfig`: map[string]string，控制节点配置
  - `computenode`: 计算节点配置
    - `replicas`: `int`，计算节点实例数
    - `port`: `int`，计算节点端口
    - `logSize`: `string`，日志存储空间大小，如：1Gi
    - `dataSize`: `string`，数据存储空间大小，如: 1Gi
    - `resources`: 资源配额
      - `limits`: 最大限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: `string`，内存资源配置，如: 1Gi
      - `requests`: 最小限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: M，内存资源配置，如: 1Gi
    - `instances`: map[int]InstanceMeta，节点实例配置
    - `volumes`: [][Volume](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，需要挂载的存储卷配置
    - `volumeMounts`: [][VolumeMount](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，存储卷挂载路径配置
    - `config`: map[string]string，计算节点配置信息
  - `datanode`: 数据节点配置
    - `replicas`: `int`，数据节点实例数
    - `port`: `int`，数据节点端口
    - `logSize`: `string`，日志存储空间大小，如：1Gi
    - `dataSize`: `string`，数据存储空间大小，如: 1Gi
    - `resources`: 资源配额
      - `limits`: 最大限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: `string`，内存资源配置，如: 1Gi
      - `requests`: 最小限制
        - `cpu`: `string`，`cpu` 资源配额，如: 1
        - `memory`: `string`，内存资源配置，如: 1Gi
    - `instances`: map[int]InstanceMeta，节点实例配置
    - `volumes`: [][Volume](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，需要挂载的存储卷配置
    - `volumeMounts`: [][VolumeMount](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，存储卷挂载路径配置
    - `config`: `map[string]string`，数据节点配置信息
  - `nodeAffinity`: [NodeAffinity](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/assign-pod-node)，节点亲和性
  - `timeMeta`: 本地时间挂载配置
    - `localTimeFileHostPath`: `string`，主机中本地时间文件所在路径
    - `localTimeFileMountPath`: `string`，本地时间文件挂载路径
  - `customMeta`: 通用元数据
    - `labels`: `map[string]string`，额外标签，会追加到创建的资源的标签中，如：`service`
    - `annotations`: `map[string]string`，额外注解，会追加到创建的资源的注解中，如：`service`
    - `podLabels`: `map[string]string`，`pod` 额外标签，会追加到创建的 `pod` 注解中
    - `podAnnotations`: `map[string]string`，`pod` 额外注解，会追加到创建的 `pod` 注解中
    - `pvcLabels`: `map[string]string`，`pvc` 额外标签，会追加到创建的 `pvc` 标签中
    - `pvcAnnotations`: `map[string]string`，`pvc` 额外注解，会追加到创建的 `pvc` 注解中
    - `serviceLabels`: `map[string]string`，`service` 额外标签，会追加到创建的 `service` 标签中
    - `serviceAnnotations`: `map[string]string`，`service` 额外注解，会追加到创建的 `service` 注解
    - `domainSuffix`: `string`，域名后缀，不填默认为 `svc.cluster.local`

###  8.2. <a name='InstanceMeta'></a>InstanceMeta

- `volumes`: [][Volume](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，需要挂载的存储卷配置
- `volumeMounts`: [][VolumeMount](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes)，存储卷挂载路径配置
- `service`: [Service.Spec](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service)，实例 `service` 配置, 配置后会为实例单独创建 `Service` 资源
- `paused`: `bool`，是否暂停实例

##  9. <a name='-1'></a>常见问题

- 如何正确设置 resources (资源配额)?

CR 中 `resources` 的设置需要满足以下要求：

1. `limits`(最大限制)中资源配额必须大于或等于 `requests` (最小限制)中对应的资源配额。
2. `requests` 的设置会强制占用机器相应的资源，请酌情设置。
3. `limits` 表示可用资源的最大值，当容器使用的内存资源超过该最大值时，该节点将出现异常。当容器使用的 CPU 资源超过该最大值时，该节点将会被限流。

- 如何解决集群中各节点因域名后缀错误造成的通信问题导致的启动失败?

1. 查看套件管理集群：

```
kubectl get ddb -ndolphindb
```

目前套件管理的集群如下, 以修改 `test` 集群为例：

```
NAME       MODE      STATUS      AGE
test      cluster   Available    2d
```

2. 执行以下命令编辑集群配置文件：

```
$ kubectl edit ddb test -ndolphindb 
```

3. 在配置文件中增加 `domainSuffix` 配置:

```yaml
apiVersion: v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  ……
  customMeta:
    domainSuffix: "svc.cluster.local"  
……
```

4. 查看 `pod` 启动情况：

```
kubectl get pod -ndolphindb
```

输出如下：

```
$ kubectl get po -n dolphindb
NAME                              READY     STATUS    RESTARTS      AGE
ddb-test-cn-0-0                    4/4     Running      0          1h
ddb-test-cn-1-0                    4/4     Running      0          1h
ddb-test-ctr-0-0                   4/4     Running      0          1h
ddb-test-ctr-1-0                   4/4     Running      0          1h
ddb-test-ctr-2-0                   4/4     Running      0          1h
ddb-test-dn-0-0                    4/4     Running      0          1h
ddb-test-dn-1-0                    4/4     Running      0          1h
ddb-test6-svc-mgr-89666f687-8bk2j  1/1     Running      0          1h
```

- 如何设置 `dataSize` 跟 `logSize` ？

二者用法如下：

`dataSize` 通过指定节点数据存储持久卷的大小决定数据库数据存储空间的大小。

`logSize` 通过指定节点日志存储持久卷的大小决定数据库日志存储空间的大小。

请根据业务需求，结合实际情况进行配置。

- 为何 `Pod` 处于 `Pending` 状态？

`Pod` 处于的 `Pending` 状态反映了资源不足，比如：

1. 使用持久化存储的 `Pod` 使用的 `PVC` 的 `StorageClass` 不存在或 `PV` 不足。
2. Kubernetes 集群中没有节点能满足 `Pod` 申请的 CPU 或内存。

此时，可以通过 `kubectl describe pod` 命令查看 `Pod` 出现 `Pending` 状态的具体原因：

```
kubectl describe po -n ${namespace} ${pod_name}
```

- 为何创建集群后 `Pod` 没有创建？

可以通过以下命令进行诊断：

```
kubectl get pod -nlphindb
kubectl describe pod $podName -ndolphindb
kubectl get statefulset -n dolphindb
kubectl describe statefulset $statefulsetName -n dolphindb
```

- 创建 DolphinDB 集群后，由于一个 `service` 对应多个 `data nodes`，如何将 `service` 与 `data node` 设置为一一对应？

1. 使用以下命令查看套件管理集群：

```
kubectl get ddb -ndolphindb
```

目前套件管理的集群如下, 以修改 test 集群为例：

```
NAME       MODE      STATUS      AGE
test      cluster   Available    2d
```

2. 查看 DolphinDB 集群数据节点，节点编号分别为 0, 1, 2：

```
kubectl get pod -ndolphindb|grep test-dn
```

输出如下：

```
ddb-test-dn-0-0                                      4/4     Running   0             2d
ddb-test-dn-1-0                                      4/4     Running   0             2d
ddb-test-dn-2-0                                      4/4     Running   0             2d
```

3. 执行以下命令编辑配置文件：

```
$ kubectl edit ddb test -ndolphindb 
```

4. 在 */spec/datanode* 增加以下部分:

```yaml
apiVersion: v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  ……
  datanode:
    instances:
      0:
        service: {}
      1:
        service: {}
      2:
        service: {}       
……
```

5. 查看 `datanode` 对应的 `port`：

```
kubectl get svc -ndolphindb |grep test-dn
```

结果如下，其中，`dn-0` 对应端口 31681，`dn-1` 对应端口 30345，`dn-2` 对应端口 32260：

```
ddb-test-dn                          NodePort    10.219.111.48    <none>        8960:32220/TCP,32210:30126/TCP,8000:31334/TCP   12m
ddb-test-dn-0                        NodePort    10.222.26.164    <none>        32210:31681/TCP                                 47s
ddb-test-dn-1                        NodePort    10.213.35.140    <none>        32210:30345/TCP                                 47s
ddb-test-dn-2                        NodePort    10.221.145.167   <none>        32210:32260/TCP                                 47s                                 
```

- 创建 DolphinDB 集群后，如何自定义挂载卷？

为 `datanode` 自定义挂载卷的操作步骤如下：

`. 查看套件管理集群：

```
kubectl get ddb -ndolphindb
```

目前套件管理的集群如下, 以修改 test 集群为例：

```
NAME       MODE      STATUS      AGE
test      cluster   Available   2d
```

2. 查看 DolphinDB 集群数据节点，节点编号分别为 0, 1, 2：

```
kubectl get pod -ndolphindb|grep test-dn
```

输出如下：

```
ddb-test-dn-0-0                                      3/3     Running   0             2d
ddb-test-dn-1-0                                      3/3     Running   0             2d
ddb-test-dn-2-0                                      3/3     Running   0             2d
```

3. 创建 `PVC` 资源。

假设要为 `ddb-test-dn-0-0` 挂载一个自定义卷，其 `PVC` 名称为 `extra-data-volume0`，且为所有数据节点均挂载一个全局 `PVC`，`PVC` 的样例文件为 `extra-data-volume0.yaml`、`extra-data-volume.yaml`，分别如下：

`extra-data-volume0.yaml`：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: extra-data-volume0
  namespace: dolphindb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-path
  volumeMode: Filesystem
```

`extra-data-volume.yaml`：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: extra-data-volume
  namespace: dolphindb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-path
  volumeMode: Filesystem
```

4. 执行以下命令:

```
kubectl apply -f extra-data-volume.yaml extra-data-volume0.yaml
```

期望输出:

```
persistentvolumeclaim/extra-data-volume persistentvolumeclaim/extra-data-volume0 created
```

5. 执行以下命令以修改 `ddb` 资源。

> :exclamation: 自定义卷挂载 extra-volume 支持 PVC/PV 以及 hostPath 两种形式：

```
$ kubectl edit ddb test -ndolphindb 
```

6. 在 */spec/datanode* 增加以下部分：

```yaml
apiVersion: v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  ……
datanode:
    ……
    volumes:
      - name: extra-data-hostpath
        hostPath:
          path: /hdd/hdd11/k8s/test/data-hostpath0
      - name: extra-data-pvc
        persistentVolumeClaim:
          claimName: extra-data-volume
    volumeMounts:
      - name: extra-data-hostpath
        mountPath: /ddb/extra-hostpath
      - name: extra-data-pvc
        mountPath: /ddb/extra-data-pvc   
    instances: 
      0:
        volumes:
          - name: extra-data-hostpath0
            hostPath:
              path: /hdd/hdd11/k8s/test/data-hostpath0
          - name: extra-data-pvc0
            persistentVolumeClaim:
              claimName: extra-data-volume0
        volumeMounts:
          - name: extra-data-hostpath0
            mountPath: /ddb/extra-hostpath0
          - name: extra-data-pvc0
            mountPath: /ddb/extra-data-pvc0      
……
```

其中，`extra-volume` 在 `ddb` 资源中通过以下字段来定义：

  - `volumes`：定义 `Pod` 需要挂载的 `volume`，为数组结构。
  - `volumeMounts`：定义 DolphinDB 所在 `container` 挂载的 `volumeMount`，为数组结构。
  - `instances.0.volumes`：`index` 为 0 的 `datanode` 节点的 `pod` 会挂载此字段声明的 `volume`。
  - `instances.0.volumeMounts`：`index` 为 0 的 `datanode` 节点的 `container` 会挂载此字段声明的 `volumeMount`。
  - `controller` 的自定义卷挂载格式和 `datanode` 声明相同，可在 `controller` 字段下声明。

- 如何将 DolphinDB 集群调度到指定节点？

可以利用节点亲和性将集群调度到指定节点：

1. 列出集群中的节点及其标签：

```
kubectl get nodes --show-labels
```

输出如下：

```
NAME      STATUS    ROLES    AGE     VERSION        LABELS
worker0   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker0
worker1   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker1
worker2   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker2
```

2. 选择一个节点，为它添加一个标签：

```
kubectl label nodes worker0 disktype=ssd
```

重新查询节点标签，输出如下：

```
$ kubectl get nodes --show-labels
NAME      STATUS    ROLES    AGE     VERSION        LABELS
worker0   Ready     <none>   1d      v1.13.0        ...,disktype=ssd,kubernetes.io/hostname=worker0
worker1   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker1
worker2   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker2
```

3. 准备一个包含节点亲和性配置的 DolphinDB CR *.yaml*配置文件：

```yaml
cat <<EOF > standalone.yaml
apiVersion: dolphindb.dolphindb.io/v1
kind: DolphinDB
metadata:
  name: test
  namespace: dolphindb
spec:
  mode: standalone
  datanode:
    dataSize: 1Gi
    logSize: 1Gi
    port: 32210
    replicas: 1
    resources:
      limits:
        cpu: 200m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 1Gi
  disableExporter: false
  disablePromtail: false
  licenseServerAddress: None
  logCleanLimit: "0.9"
  minPersistentVolumeSize: "0"
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - preference:
        matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd
      weight: 1
  storageClassName: standard
  timeMeta:
    localTimeFileHostPath: /etc/localtime
    localTimeFileMountPath: /etc/localtime
  version: v2.00.7
EOF
```

4. 使用以下命令部署该 CR 文件：

```
$ kubectl apply -f standalone.yaml
```

5. 使用以下命令查看 `pod` 绑定的节点情况：

```
$ kubectl get po -n dolphindb -o wide
NAME             READY   STATUS   RESTARTS   AGE  IP           NODE      NOMINATED NODE   READINESS GATES
ddb-test-dn-0-0  4/4     Running     0       45s  172.17.0.17  worker0   <none>           <none>
```
