baseport=$1
tool=$2
service=$3
version=$4
times=$5

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/batch

mainDir=$(pwd)/REST_Go
fuzz=$(pwd)/run_fuzzing.sh
batchDir=${mainDir}/logs/batch

# tools=("resttestgen")
# services=("user-management" "cwa-verification" "market" "project-tracking-system")
# ("features-service" "languagetool" "ncs" "news" "proxyprint" "restcountries" "scout-api" "scs" "erc20-rest-service" "genome-nexus" "person-controller" "problem-controller" "rest-study" "spring-batch-rest" "spring-boot-sample-app" "user-management" "cwa-verification" "market" "project-tracking-system") #"ocvn"


log=${batchDir}/${timeStamp}.log

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$log 2>&1

echo Logs:$log
echo STARTING at $(date) >> $log
git rev-parse HEAD

run_multiple_times(){
    i=0
    while [ $i -lt ${times} ]
    do
        i=$((i+1))
        port=$(($baseport+$i*10))
        echo RUN_START $port $tool $service
        bash -x ${fuzz} ${port} ${tool} ${service} ${version}
        echo RUN_END $port $tool $service 
    done
}

echo END at $(date) >> $log


