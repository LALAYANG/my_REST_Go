port=$1
service=$2
version=$3
api_key=$4

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mainDir=$(pwd)/REST_Go
mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/fuzzing_logs
mkdir -p $(pwd)/REST_Go/logs/fuzzing_logs/${timeStamp}

mainDir=$(pwd)/REST_Go
logDir=${mainDir}/logs
fuzzinglogs=${logDir}/fuzzing_logs/${timeStamp}
fuzz=${mainDir}/uiuc_tool_tester.py
report=${mainDir}/report.py
stopall=${mainDir}/stop_all.sh

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>${fuzzinglogs}/${timeStamp}.log 2>&1

fuzz_tool_service(){
    export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
    python3 ${fuzz} ${port} ${service} ${fuzzinglogs} ${api_key}
}

generate_report(){
    python3 ${report} ${port} ${service} restgpt ${fuzzinglogs}
}

clear_state(){
    sudo fuser -k 27018/tcp
    sudo fuser -k 8080/tcp
    bash -x $stopall
    if [[ $version == "11" ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
        export PATH=$JAVA_HOME/bin:$PATH
    else
        export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        export PATH=$JAVA_HOME/bin:$PATH
    fi
}

stop_util_docker(){
    bash -x $stopall
    tmux kill-session -t $service
    tmux kill-session -t ${service}_cov
}

cd $mainDir
clear_state
fuzz_tool_service
generate_report
stop_util_docker

echo ENDING at $(date)


