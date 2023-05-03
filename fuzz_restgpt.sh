port=$1
service=$2
version=$3

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/logs
mkdir -p $(pwd)/logs/fuzzinglogs
mkdir -p $(pwd)/logs/fuzzinglogs/${timeStamp}

mainDir=$(pwd)/REST_Go
logDir=${mainDir}/logs
fuzzinglogs=${logDir}/fuzzinglogs/${timeStamp}
fuzz=${mainDir}/uiuc_tool_tester.py
report=${mainDir}/report.py
stopall=${mainDir}/stop_all.sh

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>${fuzzinglogs}/${timeStamp}.log 2>&1

fuzz_tool_service(){
    python3 ${fuzz} ${port} ${service} ${fuzzinglogs}
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
}

cd $mainDir
clear_state
fuzz_tool_service
generate_report
stop_util_docker

echo ENDING at $(date)

