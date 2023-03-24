# DolphinDB in Kubernetes 发行说明

- [DolphinDB in Kubernetes 发行说明](#dolphindb-in-kubernetes-发行说明)
  - [DolphinDB V1.0.1 Release Notes](#dolphindb-v101-release-notes)
  - [DolphinDB V1.0.0 Release Notes](#dolphindb-v100-release-notes)

------

## DolphinDB V1.0.1 Release Notes

发行日期: 2022.04.28

DolphinDB 套件版本号：V1.0.1

**V1.0.1 新功能**

------

**优化**

- 配置项加载过程调整;

- 新增 instance service 能力，可选择性为 dolphindb 实例提供一对一的 service

- 基于 Prometheus 监控的可视化功能，引入组件：

  Prometheus：版本号 2.31.1

  Grafana 版本号 8.3.4

- DolphinDB 相关镜像绑定主机时间

- 支持日志清理容器 DolphinDB-Cleaner

- 支持 基于 Prometheus 的监控指标采集能力的容器 DolphinDB-Exporter

- 新增 DolphinDB Server 版本 v1.30.17 和 v2.00.5

- 更新 DolphinDB Server v2.00.4 版本的镜像标签为 v2.00.4-patch3


## DolphinDB V1.0.0 Release Notes

发行日期: 2022.02.25

DolphinDB 套件版本号：V1.0.0

**V1.0.0 新功能**

------

**总览**

​DolphinDB-MGR v1.0.0 为首个正式版本，它是一个 Helm chart 包，其包含 DolphinDB 在 Kubernetes 环境中的管理组件 DolphinDB-Operator 和 DolphinDB-Webserver：

- DolphinDB-Operator 组件，简称为 "ddb" 的自定义资源(CR)，自定义资源 ddb 在 Kubernetes 环境中定义 DolphinDB；

  ddb 资源主要内容

  - 单实例模式和集群模式的 DolphinDB 资源，其中集群模式分为单 Controller 模式和高可用的多 Controller 模式(raft)
  - DolphinDB 实例的两种角色：Controller 和 Datanode
  - 多 Controller 模式的 DolphinDB 集群通过名为 DolphinDB-Service-Manager 的组件进行服务管理
  - DolphinDB 集群配置项变更会触发 DolphinDB 集群内所有实例的重启
  
- DolphinDB-Webserver 组件提供可视化 Web 界面，可以在其中进行 DolphinDB 的增删改查等操作。

**主要功能**

- DolphinDB 进程容器定义在 statefulset 管理的 pod 中，通过 pvc 绑定的持久卷用于存放 data, log 和 coredump 文件。

- DolphinDB 通过 service 资源提供服务，默认服务类型为 NodePort，可在部署 DolphinDB-MGR 时通过参数 global.serviceType 来指定。

- DolphinDB 的 pod 中可额外挂载 hostPath 和 pvc 类型的卷，用于加载数据或插件。需要在 ddb 资源中进行声明。

**部署**

- 通过 Helm 工具（helm 3.0以上版本）安装 DolphinDB-MGR：

  ```
  helm install dolphindb-mgr dolphindb/dolphindb-mgr -ndolphindb --create-namespace --set global.storageClass=$StorageClass --set-file license.content=$licensePath
  ```

- 当 DolphinDB-MGR 中包含的资源准备就绪时，即可通过 dolphindb/dolphindb-webserver 这个 service 来访问可视化 web 界面。

​        详细部署文档参阅 [k8s_deployment](https://gitee.com/dolphindb/Tutorials_CN/blob/master/k8s_deployment.md) 文档





