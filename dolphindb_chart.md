# DolphinDB Chart 参数说明

本文档介绍了当前 DolphinDB 可用 Chart 参数说明。

<!-- TOC -->

- [DolphinDB Mgr 参数说明](#dolphindb-mgr-参数说明)

<!-- /TOC -->

## DolphinDB Mgr 参数说明

| **参数**                           | **说明**              |
| ------------------------ | ------------ |
| `global.registry`                  | 用户的镜像仓库，如设置为""，则默认从 dockerhub 拉取镜像。    |
| `global.repository`                | DolphinDB 的镜像仓库名称，非必要无需修改。                   |
| `global.storageClass`              | DolphinDB 使用的持久化存储的存储类，不指定则使用默认存储类。 |
| `global.serviceType`               | DolphinDB 套件在 Kubernetes 环境中提供的服务类型。ClusterIP：仅在 Kubernetes 环境内部访问；NodePort：通过主机端口可在 Kubernetes 环境内/外部访问；LoadBalancer：通过 Kubernetes 环境中的负载均衡供 Kubernetes 环境内/外部访问。 |
| `global.existingLokiAddress`       | 已部署 Loki 地址。                                     |
| `global.allNamespace`              | DolphinDB 是否在所有 namespace 生效。true: DolphinDB 可在部署在所有 namespace 并接受其管理；false: DolphinDB 仅在部署在当前 namespace 并接受其管理。 |
| `global.minPersistentVolumeSize`   | PV 的最小值 |
| `dolphindb.coreDumpDir`            | DolphinDB coreDump 输出路径。                                     |
| `dolphindb.serviceType`            | DolphinDB 在 Kubernetes 环境提供的服务类型，详情可参考 `global.serviceType`。 |
| `dolphindb.controllerDataSize`     | DolphinDB 的每个 Controller 节点的持久化存储数据的默认大小。 |
| `dolphindb.datanodeDataSize`       | DolphinDB 的每个 Datanode 节点的持久化存储数据的默认大小。   |
| `dolphindb.disableExporter`        | 是否禁止采集 DolphinDB 数据指标，默认 false   |
| `dolphindb.disablePromtail`        | 是否禁止采集 DolphinDB 日志，默认 false   |
| `dolphindb.logCleanLimit`          | 日志清理阈值,默认为 0.9   |
| `dolphindb.customMeta`             | DolphinDB 通用元数据，具体信息可以参考[customMeta](./k8s_DDB_CR_clusters.md#81-dolphindb-crd)   |
| `license.licenseServerAddress`     | license server 服务地址，仅在 DolphinDB 版本不低于 v2.00.9 或 v1.30.21 可用 |
| `license.content`                  | DolphinDB License 的内容。                                   |
| `license.resources`                | DolphinDB 每个容器的 [cpu 和 memory](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) 的默认资源配置。应与 License 中给定的资源配置相同。 |
| `dolphindb-operator.replicaCount`  | DolphinDB 套件中 dolphindb-operator 组件的副本数。           |
| `dolphindb-webserver.replicaCount` | DolphinDB 套件中 dolphindb-webserver 组件的副本数。          |
| `dolphindb-webserver.nodePortIP`   | webserver 展示 DolphinDB 时对外暴露 ip。如果 `global.serviceType` 使用 NodePort 类型，则需要指定 `nodePortIP`。可以指定 Kubernetes 集群中任意一个节点的 ip 为 `nodePortIP`。 |
| `dolphindb-cloud-portal.replicaCount` | DolphinDB 套件中 dolphindb-cloud-portal 组件的副本数。          |
| `grafana.enabled`                  | 是否安装 Grafana 组件，默认为 true。                                   |
| `prometheus.enabled`               | 是否安装 Prometheus 组件，默认为 true。                                   |
| `alertmanager.enabled`             | 是否安装 Alertmanager 组件，默认为 true。                                   |
| `node-exporter.enabled`            | 是否安装 Node-Exporter 组件，默认为 true。                                   |
| `loki.enabled`                     | 是否安装 loki 组件，默认为 true。                                   |