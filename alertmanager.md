# 如何使用 AlertManager

## 概述

Alertmanager 处理客户端应用程序(如 Prometheus 服务器)发送的警报。它负责将报警内容去重，分组并将告警内容路由到合适的接收器中，如电子邮件、钉钉、企业微信等。同时它还负责沉默和警报的抑制。

## 准备工作

- 安装 DolphinDB 套件并通过套件部署 DolphinDB 集群

## 基本使用

目前 DolphinDB 套件使用 Prometheus 作为警报发送源，当前警报触发规则可以查看[文档](./prometheus.md#dolphindb-告警规则)。如果想要修改警报触发规则，执行如下操作：

- 修改 Prometheus 配置文件，具体配置可以参考[文档](https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/prometheus-alert-rule):

```sh
$ kubectl edit cm dolphindb-mgr-prometheus-server -n dolphindb
```

- 重启 Prometheus(修改配置需重启 Pod 后生效):

```sh
// 查看当前 Prometheus 副本数
$ kubectl get deploy dolphindb-mgr-prometheus-server -n dolphindb
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
dolphindb-mgr-prometheus-server   1/1     1            1           9d

// Prometheus 缩容为 0
$ kubectl scale deploy dolphindb-mgr-prometheus-server -n dolphindb --replicas=0
// Prometheus 扩容到原先的副本数
$ kubectl scale deploy dolphindb-mgr-prometheus-server -n dolphindb --replicas=1
```

AlertManager 接收到告警之后，负责将报警内容去重，分组并将告警内容路由到合适的接收器中。同时它还负责沉默和警报的抑制。修改 AlertManager 配置需要执行如下操作：

- 修改 AlertManager 配置文件, 具体配置可以参考[文档](https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/alert-manager-config):

```sh
$ kubectl edit cm dolphindb-mgr-alertmanager -n dolphindb
```

- 重启 AlertManager(修改配置需重启 Pod 后生效):

```sh
// 查看当前 AlertManager 副本数
$ kubectl get sts dolphindb-mgr-alertmanager -n dolphindb
NAME                         READY   AGE
dolphindb-mgr-alertmanager   1/1     9d

// AlertManager 缩容为 0
$ kubectl scale sts dolphindb-mgr-alertmanager -n dolphindb --replicas=0
// AlertManager 扩容到原先的副本数
$ kubectl scale sts dolphindb-mgr-alertmanager -n dolphindb --replicas=1
```