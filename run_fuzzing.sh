port=$1
tool=$2
service=$3

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/fuzzing_logs
mkdir -p $(pwd)/REST_Go/logs/fuzzing_logs/${timeStamp}

mainDir=$(pwd)/REST_Go
fuzzlogDir=${mainDir}/logs/fuzzing_logs
logDir=${mainDir}/logs/fuzzing_logs/${timeStamp}
fuzz=${mainDir}/run_tool.py
report=${mainDir}/report.py
stopall=${mainDir}/stop_all.sh

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$logDir/$timeStamp.log 2>&1

echo Logs:$logDir
echo STARTING at $(date)

fuzz_tool_service(){
    python3 ${fuzz} $tool $service $port $logDir
}

generate_report(){
    python3 $report $port $service $tool $logDir
}

clear_state(){
    sudo fuser -k 27018/tcp
    sudo fuser -k 8080/tcp
}

stop_util_docker(){
    bash -x $stopall
}

cd $mainDir
clear_state
fuzz_tool_service
generate_report
stop_util_docker

echo ENDING at $(date)