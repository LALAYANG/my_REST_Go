baseport=$1

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/batch

mainDir=$(pwd)/REST_Go
fuzz=$(pwd)/run_fuzzing.sh
batchDir=${mainDir}/logs/batch

tools=("resttestgen")
services=("user-management" "cwa-verification" "market" "project-tracking-system")
# ("features-service" "languagetool" "ncs" "news" "proxyprint" "restcountries" "scout-api" "scs" "erc20-rest-service" "genome-nexus" "person-controller" "problem-controller" "rest-study" "spring-batch-rest" "spring-boot-sample-app" "user-management" "cwa-verification" "market" "project-tracking-system") #"ocvn"


log=${batchDir}/${timeStamp}.log

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$log 2>&1

echo Logs:$log
echo STARTING at $(date) >> $log
git rev-parse HEAD

i=0
for tool in ${tools[@]}; 
do
    for service in ${services[@]};
    do
        echo RUNNING $port $tool $service >> $log
        i=$((i+1))
        port=$(($baseport+$i*10))
        bash -x $fuzz $port $tool $service
        echo RUNEND $port $tool $service >> $log
    done
done

echo END at $(date) >> $log


