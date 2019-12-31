#!/bin/bash

extips=( "10.60.1.10" "10.60.0.10" )

#  Ping all the things!
EXIT_VAL=0
for nsc in $(kubectl get pods -o=name | grep simple-client-${id} | sed 's@.*/@@'); do
    echo "===== >>>>> PROCESSING ${nsc}  <<<<< ==========="
    for i in {1..10}; do
        echo Try ${i}
        for ip in $(kubectl exec -it "${nsc}" -- ip addr| grep inet | awk '{print $2}'); do
		if [[ "${ip}" == 10.60.4.* ]];then
                    SuccessCount=0
                    for targetIp in ${extips[@]}; do
                        if kubectl exec -it "${nsc}" -- ping -A -c 10 "${targetIp}" ; then
                            echo "NSC ${nsc} with IP ${ip} pinging TargetIP: ${targetIp} successful"
                            ((SuccessCount++))
                        else
                            echo "NSC ${nsc} with IP ${ip} pinging TargetIP: ${targetIp} unsuccessful"
                            EXIT_VAL=1
                        fi
                    done
                fi
        done
        if [ "$SuccessCount" == "2" ]; then
            break
        fi
        sleep 2
    done
    if [ ! "$SuccessCount" == "2" ]; then
        EXIT_VAL=1
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
        echo "NSC ${nsc} failed ping to external interfaces"
        kubectl get pod "${nsc}" -o wide
        echo "POD ${nsc} Network dump -------------------------------"
        kubectl exec -ti "${nsc}" -- ip addr
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
    fi

    echo "All check OK. NSC ${nsc} behaving as expected."
done
EXIT_VAL=0
for nsc in $(kubectl get pods -o=name | grep -E "ucnf-client-${id}" | sed 's@.*/@@'); do
    echo "===== >>>>> PROCESSING ${nsc}  <<<<< ==========="
    for i in {1..10}; do
        echo Try ${i}
        for ip in $(kubectl exec -it "${nsc}" -- vppctl show int addr | grep L3 | awk '{print $2}'); do
            if [[ "${ip}" == 10.60.4.* ]];then
		# Remove hidden newlines (^M)
		ip="${ip//$'\015'}"
                SuccessCount=0
                for targetIp in ${extips[@]}; do
                    # Prime the pump, its normal to get a packet loss due to arp
                    kubectl exec -it "${nsc}" -- vppctl ping "${targetIp}" repeat 10 > /dev/null 2>&1            
                    OUTPUT=$(kubectl exec -it "${nsc}" -- vppctl ping "${targetIp}" repeat 3)
                    echo "${OUTPUT}"
                    RESULT=$(echo "${OUTPUT}"| grep "packet loss" | awk '{print $6}')
                    if [ "${RESULT}" = "0%" ]; then
                        echo "NSC ${nsc} with IP ${ip} pinging TargetIP: ${targetIp} successful"
                        ((SuccessCount++))
                    else
                        echo "NSC ${nsc} with IP ${ip} pinging TargetIP: ${targetIp} unsuccessful"
                        EXIT_VAL=1
                    fi
                done
            fi
        done
        if [ "$SuccessCount" == "2" ]; then
            break
        fi
        sleep 2
    done

    if [ ! "$SuccessCount" == "2" ]; then
        EXIT_VAL=1
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
        echo "NSC ${nsc} failed ping to external interfaces"
        kubectl get pod "${nsc}" -o wide
        echo "POD ${nsc} Network dump -------------------------------"
        kubectl exec -ti "${nsc}" -- vppctl show int
        kubectl exec -ti "${nsc}" -- vppctl show int addr
        kubectl exec -ti "${nsc}" -- vppctl show memif
        echo "+++++++==ERROR==ERROR=============================================================================+++++"
    fi
done
