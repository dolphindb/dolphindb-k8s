# DolphinDB Database Cluster Deployment in Docker Containers

DolphinDB provides a Docker package for quick deployment of a distributed cluster.

This tutorial uses as an example a DolphinDB cluster with 5 data nodes on 4 centos containers. The structure of the cluster is: 

```
           => agent1 => 2 datanodes
controller => agent2 => 2 datanodes
           => agent3 => 1 datanode
```

As a cluster with 5 data nodes is not allowed with DolphinDB Community Version, please apply for an Enterprise Trial license and copy the license file dolphindb.lic to the directory ./cfg. 

To deploy the distributed cluster, we need to configure the IP address and port number for the controller node, each of the agent nodes and each of the data nodes respectively. In the DolphinDB Docker package for this tutorial, we construct a VLAN and specify 4 IP addresses (10.5.0.2 to 10.5.0.5) for the 4 containers. For this tutorial you don't need to configure them manually as all the configuration files are included in the Docker package. 

The configuration file controller.cfg:

```bash
$ cat controller.cfg
localSite=10.5.0.5:8888:master
...
```

The configuration file agent1.cfg:
```bash
$ cat agent1.cfg
mode=agent
localSite=10.5.0.2:8710:P1-agent,agent
controllerSite=10.5.0.5:8888:master
```

The configuration file cluster.nodes:
```bash
$ cat cluster.nodes
localSite,mode
10.5.0.2:8710:P1-agent,agent
10.5.0.2:8711:P1-node1,datanode
10.5.0.2:8712:P1-node2,datanode
10.5.0.3:8810:P2-agent,agent
10.5.0.3:8811:P2-node1,datanode
10.5.0.3:8812:P2-node2,datanode
10.5.0.4:8910:P3-agent,agent
10.5.0.4:8911:P3-node1,datanode
```

Please note that agent.cfg and cluster.cfg both contain lanCluster=0, as the UDP protocol does not work in a Docker virtual network environment.

For this tutorial, you need to install both Docker Community Edition (CE) and Docker Compose on your machine. Please refer to [Docker CE documentation](https://docs.docker.com/install/) and [Docker Compose documentation](https://docs.docker.com/compose/install/#install-compose). Follow the Docker documentation to install Docker CE and Docker Compose. After installation, you should be able to get the version number by running the following commands in Linux.

```bash
$ docker -v
$ docker-compose --version
```
#### 1. Build DophinDB Docker image

(1) Download the DophinDB Docker package.

The DolphinDB Docker package is open source and is available at [Github](https://github.com/dolphindb/Tutorials_CN/blob/master/docker/DolphinDB-Docker-Compose.zip). 

(2) Build DophinDB Docker image.

We can get a DophinDB Docker image containing the newest version of DolphinDB server by running 'docker build'. 

```bash
$ cd ./DolphinDB-Docker-Compose/Dockerbuild
$ docker build -t ddb:latest ./
```

Run 'docker images' to make sure the DolphinDB Docker image is built sucessfully.

```bash
$ docker images
REPOSITORY   TAG     IMAGE ID       CREATED         SIZE
ddb          latest  4268ac618977   5 seconds ago   420MB
```
#### 2. Create containers and get started

Create containers for the controller and agents and spin up the cluster by running the following script:
```bash
cd ./DolphinDB-Docker-Compose
docker-compose up -d
```

The default startup script in the container automatically starts the controller node and all the agent nodes.

```bash
$ cd ./DolphinDB-Docker-Compose
$ docker-compose up -d
Creating network "20190121-dolphindb-docker-compose_dbnet" with driver "bridge"
Creating ddbcontroller ... done
Creating ddbagent2     ... done
Creating ddbagent3     ... done
Creating ddbagent1     ... done
```

#### 3. Access the cluster

After the controller and all the agent nodes are started, we can start or stop data nodes on DolphinDB cluster management web interface. Enter http://localhost:8888/ in the address bar of your browser (currently supporting Chrome and Firefox) to access the web-based cluster manager. Start all the data nodes and then click on the "refresh" button to check the status of the nodes. When you see the "State" column is full of green check marks, all the nodes have been successfully started.

![image](https://github.com/dolphindb/Tutorials_CN/blob/master/images/docker/cluster_web.png?raw=true)
