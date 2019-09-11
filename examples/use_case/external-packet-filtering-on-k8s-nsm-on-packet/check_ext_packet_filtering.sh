#!/bin/bash

validate_ip() {
  re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
   re+='0*(1?[0-9]{1,2}|2([<200c><200b>0-4][0-9]|5[0-5]))$'

  if ! [[ $1 =~ $re ]]; then
    echo "ERROR: Must provide a valid IPv4 IP (Got: $1)"
    echo "  Usage: ./check_ext_packet_filtering.sh <Remote IP>"
    exit 1
  fi
}

if [ ! -z "$1" ]; then
 validate_ip $1
fi

kubectl wait -n default --timeout=150s --for condition=Ready --all pods

#  Ping all the things!
EXIT_VAL=0
for nsc in $(kubectl get pods -o=name | grep simple-client | sed 's@.*/@@'); do
    echo "===== >>>>> PROCESSING ${nsc}  <<<<< ==========="
    for i in {1..10}; do
        echo Try ${i}
        for ip in $(kubectl exec -it "${nsc}" -- ip addr| grep inet | awk '{print $2}'); do
            if [[ "${ip}" == 10.60.3.* ]];then
                lastSegment=$(echo "${ip}" | cut -d . -f 4 | cut -d / -f 1)
                targetIp="$1"
                endpointName="External Physical Server"
            fi

            if [ -n "${targetIp}" ]; then
                if kubectl exec -it "${nsc}" -- ping -A -c 10 "${targetIp}" ; then
                    echo "NSC ${nsc} with IP ${ip} pinging ${endpointName} TargetIP: ${targetIp} successful"
                    PingSuccess="true"
                else
                    echo "NSC ${nsc} with IP ${ip} pinging ${endpointName} TargetIP: ${targetIp} unsuccessful"
                    EXIT_VAL=1
                fi
            fi
        done
        if [ ${PingSuccess} ]; then
            break
        fi
        sleep 2
    done
    if [ -z ${PingSuccess} ]; then
        EXIT_VAL=1
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
        echo "NSC ${nsc} failed ping to $endpointName"
        kubectl get pod "${nsc}" -o wide
        echo "POD ${nsc} Network dump -------------------------------"
        kubectl exec -ti "${nsc}" -- ip addr
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
    fi

    echo "All check OK. NSC ${nsc} behaving as expected."

    unset targetIp
    unset endpointName
    unset PingSuccess
done

for nsc in $(kubectl get pods -o=name | grep -E "ucnf-client" | sed 's@.*/@@'); do
    echo "===== >>>>> PROCESSING ${nsc}  <<<<< ==========="
    for i in {1..10}; do
        echo Try ${i}
        for ip in $(kubectl exec -it "${nsc}" -- vppctl show int addr | grep L3 | awk '{print $2}'); do
            if [[ "${ip}" == 10.60.3.* ]];then
                lastSegment=$(echo "${ip}" | cut -d . -f 4 | cut -d / -f 1)
                targetIp="$1"
                endpointName="External Physical Server"
		# Remove hidden newlines (^M)
		ip="${ip//$'\015'}"
            fi

            if [ -n "${targetIp}" ]; then
                # Prime the pump, its normal to get a packet loss due to arp
                kubectl exec -it "${nsc}" -- vppctl ping "${targetIp}" repeat 10 > /dev/null 2>&1            
                OUTPUT=$(kubectl exec -it "${nsc}" -- vppctl ping "${targetIp}" repeat 3)
                echo "${OUTPUT}"
                RESULT=$(echo "${OUTPUT}"| grep "packet loss" | awk '{print $6}')
                if [ "${RESULT}" = "0%" ]; then
                    echo "NSC ${nsc} with IP ${ip} pinging ${endpointName} TargetIP: ${targetIp} successful"
                    PingSuccess="true"
                    EXIT_VAL=0
                else
                    echo "NSC ${nsc} with IP ${ip} pinging ${endpointName} TargetIP: ${targetIp} unsuccessful"
                    EXIT_VAL=1
                fi
                
                unset targetIp
                unset endpointName
            fi
        done
        if [ ${PingSuccess} ]; then
            break
        fi
        sleep 2
    done

    if [ -z ${PingSuccess} ]; then
        EXIT_VAL=1
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
        echo "NSC ${nsc} failed ping to $endpointName"
        kubectl get pod "${nsc}" -o wide
        echo "POD ${nsc} Network dump -------------------------------"
        kubectl exec -ti "${nsc}" -- vppctl show int
        kubectl exec -ti "${nsc}" -- vppctl show int addr
        kubectl exec -ti "${nsc}" -- vppctl show memif
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
    fi
    unset targetIp
    unset endpointName
    unset PingSuccess
done

exit ${EXIT_VAL}
