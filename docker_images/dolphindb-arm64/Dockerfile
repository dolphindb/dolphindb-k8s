FROM cyphernode/alpine-glibc-base:arm64-v3.15.4_2.31-0

COPY server /data/ddb/server

RUN apk add tzdata

ENTRYPOINT ["sh", "-c", "cd /data/ddb/server;./dolphindb -console 0 -stdoutLog true -home data -script dolphindb.dos"]