#!/bin/bash

NET=codis_nw
SUBNET=172.30.30.0/24
IPPREFIX=172.30.30
docker network inspect $NET >/dev/null 2>&1
if [ $? -ne 0 ]; then
    docker network create -d bridge --subnet $SUBNET $NET
fi

ZOOPATH=/opt/zookeeper
for i in {11..13}; do
    docker kill ${i}zk >/dev/null 2>&1
    docker rm ${i}zk
    docker run --net=${NET} --ip=${IPPREFIX}.${i} -d --name ${i}zk zookeeper \
	/bin/bash -c \
	"echo `expr $i - 10` > ${ZOOPATH}/data/myid && ${ZOOPATH}/bin/zkServer.sh start-foreground"
done

for i in {14..17}; do
    docker kill ${i}codis-server >/dev/null 2>&1
    docker rm ${i}codis-server
    docker run --user codis --net=${NET} --ip=${IPPREFIX}.${i} -d \
	--name ${i}codis-server codis-base \
	/bin/bash -c \
	"cd /home/codis/bin && codis-server"
done


i=18
docker kill ${i}codis-config >/dev/null 2>&1
docker rm ${i}codis-config
docker run --user codis --net=${NET} --ip=${IPPREFIX}.${i} -d \
    -p 18087:18087 --name ${i}codis-config codis-base \
    /bin/bash -c \
    "cd /home/codis/bin && codis-config dashboard"


sleep 5
docker exec -it ${i}codis-config /bin/bash -c \
"cd /home/codis/bin && codis-config slot init && \
codis-config server add 1 172.30.30.14:6379 master && \
codis-config server add 1 172.30.30.15:6379 slave && \
codis-config server add 2 172.30.30.16:6379 master && \
codis-config server add 2 172.30.30.17:6379 slave && \
codis-config slot range-set 0 511 1 online && \
codis-config slot range-set 512 1023 2 online
"

i=19
docker kill ${i}codis-proxy >/dev/null 2>&1
docker rm ${i}codis-proxy
docker run --user codis --net=${NET} --ip=${IPPREFIX}.${i} -d \
    -p 9000:9000 -p 19000:19000 -p 11000:11000 --name ${i}codis-proxy codis-base \
    /bin/bash -c \
"cd /home/codis/bin && \
echo proxy_id=proxy${i} >> /home/codis/bin/config.ini &&  \
codis-proxy"

sleep 5
docker exec -it 18codis-config /bin/bash -c \
"cd /home/codis/bin && codis-config proxy online proxy${i}"
