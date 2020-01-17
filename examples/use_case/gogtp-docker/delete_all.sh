#! /bin/bash
docker rm enb mme sgw pgw sgi-server ue-ext --force
docker network rm $(docker network ls | grep lte | awk {'print $1}')
