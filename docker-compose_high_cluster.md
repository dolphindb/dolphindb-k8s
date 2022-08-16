##  基于docker-compose的DolphinDB多容器集群部署

<!-- TOC -->

- [基于docker-compose的DolphinDB多容器集群部署](#基于docker-compose的dolphindb多容器集群部署)
  - [1. 环境准备](#1-环境准备)
  - [2. 集群结构介绍](#2-集群结构介绍)
  - [3. 快速体验（单机非高可用版）](#3-快速体验单机非高可用版)
  - [4. 生产环境（单机高可用版）](#4-生产环境单机高可用版)
    - [4.1 部署介绍](#41-部署介绍)
    - [4.2 使用步骤](#42-使用步骤)
  - [5. 生产环境（多机高可用版）](#5-生产环境多机高可用版)
    - [4.1 部署介绍](#41-部署介绍-1)
    - [4.2 使用步骤](#42-使用步骤-1)
  - [6. 常见问题](#6-常见问题)
    - [6.1 如何升级DolphinDB版本](#61-如何升级dolphindb版本)
    - [6.2 报错及解决方案](#62-报错及解决方案)

<!-- /TOC -->
 `docker compose` 项目是 Docker 官方的开源项目，负责实现对 Docker 容器集群的快速编排。

本文介绍如何使用`docker compose`进行 DolphinDB 多容器普通集群和高可用集群的部署，以及可能出现的相关问题。

### 1. 环境准备

- **安装 Docker**

docker compose是基于docker运行的，安装docker compose前需要先安装docker。docker 可以方便地在 Linux / Mac OS / Windows 平台安装，安装方法请参考 [Docker 官方文档](https://www.docker.com/products/docker)。

- **安装docker compose**

本教程推荐用如下方法从 [官方 GitHub Release](https://github.com/docker/compose/releases)上下载编译好的docker compose二进制文件，具体安装和使用方法可参考[docker compose官方文档](https://docs.docker.com/compose/install/compose-plugin/)

- **主机信息**

  - 单机版：
  
    | 主机名    | IP           | 部署服务  | 数据盘挂载 |
    | :-------- | :----------- | :-------- | :--------- |
    | cnserver9 | xx.xx.xx.122 | dolphindb | /ddbdocker |
  
  - 多机版：
  
  | 主机名 | IP          | 部署服务                               | 数据盘挂载 |
  | :----- | :---------- | :------------------------------------- | :--------- |
  | host1  | xx.xx.xx.81 | dolphindb controller1&dolphindb agent1 | /host1     |
  | host2  | xx.xx.xx.82 | dolphindb controller2&dolphindb agent2 | /host2     |
  | host3  | xx.xx.xx.83 | dolphindb controller3&dolphindb agent3 | /host3     |

### 2. 集群结构介绍

DolphinDB 提供数据、元数据以及客户端的高可用方案，使得数据库节点发生故障时，数据库依然可以正常运作，保证业务不会中断。而 DolphinDB 采用多副本机制和 raft 协议，确保在集群中多个控制节点存在的情况下有一半节点宕机且多数据副本存在的情况下仅有一个数据副本可用，集群仍然可以提供服务。

DolphinDB Cluster包括四种类型节点：数据节点（data node），计算节点( compute node ) ，代理节点（agent）和控制节点（controller）。

- 数据节点：用于数据存储。可以在数据节点创建分布式数据库表。
- 计算节点：只用于计算，包括流计算、分布式关联、机器学习等。
- 代理节点：用于关闭或开启数据节点。
- 控制节点：用于集群元数据的管理和数据节点间任务的协调。

> 注意：
>
> 1.集群中任意一个数据节点或计算节点都可以作为客户端，进行数据读取，但是控制节点仅用于内部管理协调，不能作为任务的主入口；
>
> 2.节点的IP地址需要使用内网IP。如果使用外网地址，不能保证节点间网络通信性能。在docker 容器之间为了保证通讯，一般要提前设置虚拟网桥并分配虚拟ip地址；
>
> 3.每个物理节点必须要有一个代理节点，用于启动和关闭该物理节点上的一个或多个数据节点；



### 3. 快速体验（单机非高可用版）

该部分是基于 `dolphindb/dolphindb:v2.00.5` 镜像 `docker compose` 多容器集群部署的快速体验，由于社区版认证文件的对数据节点和控制节点的限制，这里只介绍部署一个控制节点的容器和一个数据节点的容器的项目，其中DolphinDB的镜像采用的是 `v2.00.5`镜像。

- 登录机器，执行如下命令：

  ```shell
  $ git clone https://dolphindb.net/dolphindb/dolphindb_k8s.git
  $ cd dolphindb_k8s/docker-compose/ddb_cluster_quick && docker-compose up -d
  ```

  预期输出

  ```
  [+] Running 2/2
   ⠿ ddb_controller Pulled                                                                                                 4.5s
   ⠿ ddb_agent1 Pulled                                                                                                     4.4s
  [+] Running 3/3
   ⠿ Network dev_ddb           Created                                                                                     0.1s
   ⠿ Container ddb_controller  Started                                                                                     0.5s
   ⠿ Container ddb_agent1      Started                                                                                     0.8s
  ```

- 在浏览器中，输入本机ip:端口号(8900)，结果如下图所示

![docker_test_outcome](./images/ddb_high_cluster/docker_test_outcome.png)



### 4. 生产环境（单机高可用版）

#### 4.1 部署介绍

​	本节内容采用 `docker compose` 在单机多个容器中快速部署多控制节点和多数据节点的高可用集群，您可直接从网上下载一个基于 `docker compose` 部署的具有三个控制节点和三个数据节点 DolphinDB 高可用集群项目，使用前需要确保网络连通。本次所使用的 DolphinDB 镜像是 `v2.00.5` (社区版用户不支持搭建高可用集群)，企业版用户需要替换证书文件。

#### 4.2 使用步骤

- 登录机器执行如下命令，获取项目内容，

  ```shell
  $ git clone https://dolphindb.net/dolphindb/dolphindb_k8s.git
  ```

- 执行如下命令，查看项目目录架构

  ```shell
  $ cd dolphindb_k8s/docker-compose/ddb_high_3cluster && tree ./
  ```

  预期输出：

  ```
  ./
  ├── cfg
  │   ├── agent1.cfg
  │   ├── agent2.cfg
  │   ├── agent3.cfg
  │   ├── cluster.cfg
  │   ├── cluster.nodes
  │   ├── controller1.cfg
  │   ├── controller2.cfg
  │   └── controller3.cfg
  ├── cluster
  │   ├── agent
  │   │   ├── data
  │   │   └── log
  │   └── controller
  │       ├── data
  │       └── log
  ├── docker-compose.yml
  └── dolphindb.lic
  
  8 directories, 10 files
  ```

  文件说明如下：

  | 文件（夹）名       | 文件（夹）说明                                  | 宿主机映射路径（相对路径）                                   | 容器映射路径（绝对路径）                                     |
  | ------------------ | ----------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | docker-compose.yml | 用于构建容器服务                                | 无                                                           | 无                                                           |
  | dolphindb.lic      | DolphinDB企业版的证书文件                       | ./dolphindb.lic                                              | /data/ddb/server/dolphindb.lic                               |
  | cfg                | 用于存储DolphinDB各角色相关配置文件             | ./cfg/agent1.cfg;<br>./cfg/agent2.cfg;<br/>./cfg/agent3.cfg; <br/>./cfg/cluster.cfg;<br/>./cfg/cluster.nodes;<br/> ./cfg/controller1.cfg;<br/>./cfg/controller2.cfg; <br/>./cfg/controller3.cfg | /data/ddb/server/clusterDemo/config/agent1.cfg; /data/ddb/server/clusterDemo/config/agent2.cfg; /data/ddb/server/clusterDemo/config/agent3.cfg; /data/ddb/server/clusterDemo/config/cluster.cfg; /data/ddb/server/clusterDemo/config/cluster.nodes; /data/ddb/server/clusterDemo/config/controller1.cfg; /data/ddb/server/clusterDemo/config/controller2.cfg; /data/ddb/server/clusterDemo/config/controller3.cfg; |
  | cluster            | 用于存储各容器所部署的DolphinDB的数据和日志内容 | ./cluster/controller/data;<br/>./cluster/controller/log; <br/>./cluster/agent/data;<br/>./cluster/agent/log | /data/ddb/server/clusterDemo/data;<br/> /data/ddb/server/clusterDemo/log |

- 执行如下命令启动docker compose服务，

  ```shell
  $ docker-compose up -d
  ```

  预期输出：

  ```
  [+] Running 7/7
   ⠿ Network dev_ddb            Created                                                                                    0.2s
   ⠿ Container ddb_controller3  Started                                                                                    1.0s
   ⠿ Container ddb_controller1  Started                                                                                    1.0s
   ⠿ Container ddb_controller2  Started                                                                                    0.9s
   ⠿ Container ddb_agent3       Started                                                                                    1.9s
   ⠿ Container ddb_agent1       Started                                                                                    1.9s
   ⠿ Container ddb_agent2       Started                                                                                    1.8s
  ```

- 在浏览器中，输入本机ip:端口号(8901)，在浏览器看到如下结果，说明运行正常

![docker_high_outcome](./images/ddb_high_cluster/docker_high_outcome.png)

​	点击右上角登录按钮输入用户名 admin 和密码123456登录，来启动容器服务等；

- 自定义添加、删改节点和使用各类高可用功能可结合[DolphinDB高可用集群部署教程](https://gitee.com/dolphindb/Tutorials_CN/blob/master/安装和部署/ha_cluster_deployment.md)和[docker compose官方文档](https://docs.docker.com/compose/compose-file/)进行操作

### 5. 生产环境（多机高可用版）

#### 4.1 部署介绍

​	本节内容采用 `docker compose` 在多机多个容器中快速部署多控制节点和多数据节点的高可用集群，您可直接从网上下载一个在三台机器上基于 `docker compose` 部署的具有三个控制节点和三个数据节点DolphinDB高可用集群项目，使用前需要确保网络连通。本次所使用的DolphinDB镜像是`v2.00.5` (社区版用户不支持搭建高可用集群)，企业版用户需要替换证书文件。

#### 4.2 使用步骤

- 在三台机器上分别执行如下命令获取项目内容：

  host1:

  ```shell
  $ git clone https://dolphindb.net/dolphindb/dolphindb_k8s.git  \
  && cd dolphindb_k8s/docker-compose/ddb_high_cluster_multi_machine/host1
  ```

  host2:

  ```shell
  $ git clone https://dolphindb.net/dolphindb/dolphindb_k8s.git  \
  && cd dolphindb_k8s/docker-compose/ddb_high_cluster_multi_machine/host2
  ```

  host3:

  ```shell
  $ git clone https://dolphindb.net/dolphindb/dolphindb_k8s.git  \
  && cd dolphindb_k8s/docker-compose/ddb_high_cluster_multi_machine/host3
  ```

- 在三台机器的项目内容目录下分别执行如下命令查看项目目录结构：

  ```shell
  $ tree ./
  ```

  预期输出：

  - host1:

    ```
    ./
    ├── cfg
    │   ├── agent1.cfg
    │   ├── cluster.cfg
    │   ├── cluster.nodes
    │   └── controller1.cfg
    ├── cluster
    │   ├── agent
    │   │   ├── data
    │   │   └── log
    │   └── controller
    │       ├── data
    │       └── log
    ├── docker-compose.yml
    └── dolphindb.lic
    
    8 directories, 6 files
    ```

  - host2:

    ```
    ./
    ├── cfg
    │   ├── agent2.cfg
    │   ├── cluster.cfg
    │   ├── cluster.nodes
    │   └── controller2.cfg
    ├── cluster
    │   ├── agent
    │   │   ├── data
    │   │   └── log
    │   └── controller
    │       ├── data
    │       └── log
    ├── docker-compose.yml
    └── dolphindb.lic
    
    8 directories, 6 files
    ```

  - host3:

    ```
    ./
    ├── cfg
    │   ├── agent3.cfg
    │   ├── cluster.cfg
    │   ├── cluster.nodes
    │   └── controller3.cfg
    ├── cluster
    │   ├── agent
    │   │   ├── data
    │   │   └── log
    │   └── controller
    │       ├── data
    │       └── log
    ├── docker-compose.yml
    └── dolphindb.lic
    
    8 directories, 6 files
    ```

  文件说明如下：

  | 文件（夹）名       | 文件（夹）说明                                  | 宿主机映射路径（相对路径）                                   | 容器映射路径（绝对路径）                                     |
  | ------------------ | ----------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | docker-compose.yml | 用于构建容器服务                                | 无                                                           | 无                                                           |
  | dolphindb.lic      | DolphinDB企业版的证书文件                       | ./dolphindb.lic                                              | /data/ddb/server/dolphindb.lic                               |
  | cfg                | 用于存储DolphinDB各角色相关配置文件             | ./cfg/agent1.cfg;<br/>./cfg/agent2.cfg;<br/>./cfg/agent3.cfg;<br/> ./cfg/cluster.cfg;<br/>./cfg/cluster.nodes; <br/>./cfg/controller1.cfg;<br/>./cfg/controller2.cfg; <br/>./cfg/controller3.cfg | /data/ddb/server/clusterDemo/config/agent1.cfg; /data/ddb/server/clusterDemo/config/agent2.cfg; /data/ddb/server/clusterDemo/config/agent3.cfg; /data/ddb/server/clusterDemo/config/cluster.cfg; /data/ddb/server/clusterDemo/config/cluster.nodes; /data/ddb/server/clusterDemo/config/controller1.cfg; /data/ddb/server/clusterDemo/config/controller2.cfg; /data/ddb/server/clusterDemo/config/controller3.cfg; |
  | cluster            | 用于存储各容器所部署的DolphinDB的数据和日志内容 | ./cluster/controller/data;<br/>./cluster/controller/log; <br/>./cluster/agent/data;<br/>./cluster/agent/log | /data/ddb/server/clusterDemo/data; <br/>/data/ddb/server/clusterDemo/log |

  所对应部署的集群服务的各节点及其容器信息如下

  | 容器名称（唯一） | 部署服务类型      | 宿主机ip  | 对应节点名称、类型、端口                     |
  | ---------------- | ----------------- | --------- | -------------------------------------------- |
  | ddb_controller1  | 控制节点          | 10.0.0.81 | controller1,controller,8901                  |
  | ddb_controller2  | 控制节点          | 10.0.0.82 | controller2,controller,8902                  |
  | ddb_controller3  | 控制节点          | 10.0.0.83 | controller3,controller,8903                  |
  | ddb_agent1       | 代理节点&数据节点 | 10.0.0.81 | agent1,agent,8710<br/>P1-node1,datanode,8711 |
  | ddb_agent2       | 代理节点&数据节点 | 10.0.0.82 | agent2,agent,8810<br/>P2-node1,datanode,8811 |
  | ddb_agent3       | 代理节点&数据节点 | 10.0.0.83 | agent3,agent,8910<br/>P3-node1,datanode,8911 |

  > 注：
  >
  > 1.由于在文件映射过程中宿主机文件目录会始终覆盖对应容器的内容，因此在创建容器时要保证data、log目录下为空以及相关配置文件内容；
  >
  > 2.由于在实际使用过程中，宿主机的ip与本教程介绍的不一样，因此要根据[DolphininDB 多服务器集群部署](https://gitee.com/dolphindb/Tutorials_CN/blob/master/multi_machine_cluster_deployment.md)所介绍将配置文件中的ip地址改为实际使用过程中的宿主机的ip，同时要保证这些宿主机之间、容器与容器之间、宿主机与容器之间可以通信。

- 在三台服务器的项目目录下（docker-compose.yml文件同目录下）分别执行如下命令启动服务：

  ```shell
  $ docker-compose up -d
  ```

  预期输出：

  - host1：

    ```
    [+] Running 3/3
     ⠿ Network dev_ddb            Created                                                                                0.1s
     ⠿ Container ddb_controller1  Started                                                                                1.7s
     ⠿ Container ddb_agent1       Started                                                                                3.3s
    ```

  - host2:

    ```
    [+] Running 3/3
     ⠿ Network dev_ddb            Created                                                                                0.1s
     ⠿ Container ddb_controller2  Started                                                                                1.4s
     ⠿ Container ddb_agent2       Started                                                                                3.2s
    ```

  - host3:

    ```
    [+] Running 3/3
     ⠿ Network dev_ddb            Created                                                                                0.1s
     ⠿ Container ddb_controller3  Started                                                                                1.7s
     ⠿ Container ddb_agent3       Started                                                                                3.4s
    ```

- 在浏览器中，输入本机ip:端口号(8901)，在浏览器看到如下结果，说明运行正常

![docker_high_outcome](./images/ddb_high_cluster/docker_high_outcome.png)

点击右上角登录按钮输入用户名admin和密码123456登录，来启动容器服务等；

- 自定义添加、删改节点和使用各类高可用功能可结合[DolphinDB高可用集群部署教程](https://gitee.com/dolphindb/Tutorials_CN/blob/master/安装和部署/ha_cluster_deployment.md)和[docker compose官方文档](https://docs.docker.com/compose/compose-file/)进行操作



### 6. 常见问题

#### 6.1 如何升级DolphinDB版本

- 选择所需要升级后使用的DolphinDB镜像，此处为 `v2.00.6` 版本的镜像 `dolphindb/dolphindb:v2.00.6` 为例

- 如果是想升级所有容器的DolphinDB版本，在docker-compose.yml的同级目录下找到.env文件，修改其有关镜像的环境变量如下

  ```
  IMAGE=dolphindb/dolphindb:v2.00.6
  ```

- 在docker-compose.yml所在目录下执行如下命令重启正在运行的服务

  ```shell
  $ docker-compose down && docker-compose up -d
  ```

  预期输出：

  ```
  [+] Running 7/7
   ⠿ Container ddb_agent3       Removed                                                                                    1.6s
   ⠿ Container ddb_agent1       Removed                                                                                    1.6s
   ⠿ Container ddb_agent2       Removed                                                                                    1.3s
   ⠿ Container ddb_controller1  Removed                                                                                    2.7s
   ⠿ Container ddb_controller2  Removed                                                                                    2.6s
   ⠿ Container ddb_controller3  Removed                                                                                    2.6s
   ⠿ Network dev_ddb            Removed                                                                                    0.1s
  ```


#### 6.2 报错及解决方案

- 报错信息如下

  ```
  but no declaration was found in the volumes section.
  ```

  说明没有事先声明数据卷，或在数据卷映射的时候没有采用相对路径

  解决方案：在文件中事先配置数据卷名称，或采用相对路径进行文件映射

  



