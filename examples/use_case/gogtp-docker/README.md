### Running container (docker) version of Go-GTP 
Before starting, make sure you are on a node that already has Docker installed.

By default, pre-built images containing the necessary Go-GTP binaries and configuration files (yaml) are used. If you prefer to build your own image this can be done using the scripts avaialble in the `examples/network_functions/go-gtp` directory. If you build your own images make sure to update the provided scripts to use these images when running the containers.

Deploy the setup using the provided script:
```
$ ./run_all.sh
```

Once deployed, start the EPC functions in separate terminal windows using the below commands:
```
$ docker exec -it pgw pgw
$ docker exec -it sgw sgw
$ docker exec -it mme mme
$ docker exec -it enb enb
```
_You can run these detached as well, or modify the `run_all.sh` script to start the functionality automatically. Do note that the networks/interfaces must be attached before the applications start, otherwise they will fail_

To test connctivity, the following steps can be used from two separeate terminals
```
## Terminal 1
$ docker exec -it sgi-server /bin/bash
  $ apt-get update
  $ apt-get -y install python3 iproute2
  $ ip r add 10.0.0.201 via 10.0.1.254 dev eth1
  $ python3 -m http.server 80

## Terminal 2
$ docker exec -it ue-ext /bin/bash
  $ apt-get update
  $ apt-get -y install iputils-ping wget iproute2
  $ ip r add 10.0.1.201 via 10.0.0.254 dev eth1
  $ wget http://10.0.1.201
  # You should see wget fetching index.html from the remote web server
  # You can use ping 10.0.1.201 as an alternative to check connectivity
```

### Clean up containers and networks
You can clean the environment using the provided script:
```
$ ./delete_all.sh
```
