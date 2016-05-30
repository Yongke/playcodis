#!/bin/bash

docker build --force-rm -t zookeeper -f Dockerfile.zookeeper .
docker build --force-rm -t codis-base -f Dockerfile.codis .

