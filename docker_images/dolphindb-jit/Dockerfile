FROM centos:7.6.1810 as builder

ARG base_url="http://www.dolphindb.cn/downloads/"
ARG dolphindb_version="DolphinDB_Linux64_V2.00.7_JIT.zip"
ARG dolphindb="${base_url}${dolphindb_version}"

RUN mkdir -p /data/ddb
ADD $dolphindb /data/ddb/
RUN yum install -y unzip

RUN (cd /data/ddb/ && unzip /data/ddb/${dolphindb_version})
RUN chmod 755 /data/ddb/server/dolphindb
RUN mkdir /data/ddb/server/data
COPY libtinfo.so.5 /data/ddb/server/

FROM 192.168.1.240/dolphindb/alpine-glibc:glibc-2.33 as prod
RUN apk add gdb
COPY --from=0 /data/ddb/server /data/ddb/server

ENTRYPOINT ["sh", "-c", "cd /data/ddb/server;export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH;./dolphindb -console 0 -stdoutLog true -home data -script dolphindb.dos"]