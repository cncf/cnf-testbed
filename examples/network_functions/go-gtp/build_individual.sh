#! /bin/bash
docker build -t gogtp:enb enb/
docker build -t gogtp:mme mme/
docker build -t gogtp:pgw pgw/
docker build -t gogtp:sgw sgw/
