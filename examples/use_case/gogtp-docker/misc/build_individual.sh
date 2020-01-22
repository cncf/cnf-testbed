#! /bin/bash
docker build -t gogtp:enb -f GoGTP-ENB .
docker build -t gogtp:mme -f GoGTP-MME .
docker build -t gogtp:pgw -f GoGTP-PGW .
docker build -t gogtp:sgw -f GoGTP-SGW .
