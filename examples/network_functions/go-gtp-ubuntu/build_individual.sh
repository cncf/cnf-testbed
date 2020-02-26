#! /bin/bash
docker build -t gogtpu:enb enb/
docker build -t gogtpu:mme mme/
docker build -t gogtpu:pgw pgw/
docker build -t gogtpu:sgw sgw/
