docker ps|grep codis-base| awk '{print $1}'|xargs docker kill
docker ps|grep zookeeper| awk '{print $1}'|xargs docker kill
