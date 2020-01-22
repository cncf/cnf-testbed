#! /bin/bash 
docker network create lte-euu --subnet 10.0.0.0/24 --ip-range 10.0.0.128/24
docker network create lte-s11 --subnet 172.22.0.0/24 --ip-range 172.22.0.128/24
docker network create lte-s1u --subnet 172.21.0.0/24 --ip-range 172.21.0.128/24
docker network create lte-s1c --subnet 172.21.1.0/24 --ip-range 172.21.1.128/24
docker network create lte-s5u --subnet 172.25.0.0/24 --ip-range 172.25.0.128/24
docker network create lte-s5c --subnet 172.25.1.0/24 --ip-range 172.25.1.128/24
docker network create lte-sgi --subnet 10.0.1.0/24 --ip-range 10.0.1.128/24

docker run --name pgw --cap-add=NET_ADMIN --tty --detach -it soelvkaer/gogtp:pgw
docker run --name sgw --cap-add=NET_ADMIN --tty --detach -it soelvkaer/gogtp:sgw
docker run --name mme --cap-add=NET_ADMIN --tty --detach -it soelvkaer/gogtp:mme
docker run --name enb --cap-add=NET_ADMIN --tty --detach -it soelvkaer/gogtp:enb
docker run --name sgi-server --cap-add=NET_ADMIN --tty --detach -it ubuntu:18.04
docker run --name ue-ext --cap-add=NET_ADMIN --tty --detach -it ubuntu:18.04

docker network connect lte-euu --ip 10.0.0.254 enb
docker network connect lte-s1u --ip 172.21.0.11 enb
docker network connect lte-s1c --ip 172.21.1.11 enb

docker network connect lte-s11 --ip 172.22.0.12 mme
docker network connect lte-s1c --ip 172.21.1.12 mme

docker network connect lte-s11 --ip 172.22.0.13 sgw
docker network connect lte-s1u --ip 172.21.0.13 sgw
docker network connect lte-s5u --ip 172.25.0.13 sgw
docker network connect lte-s5c --ip 172.25.1.13 sgw

docker network connect lte-s5u --ip 172.25.0.14 pgw
docker network connect lte-s5c --ip 172.25.1.14 pgw
docker network connect lte-sgi --ip 10.0.1.254 pgw

docker network connect lte-euu --ip 10.0.0.201 ue-ext
docker network connect lte-sgi --ip 10.0.1.201 sgi-server
