service=$1
version=$2
tool=$3
baseport=$4
times=$5

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mainDir=$(pwd)
mkdir -p $(pwd)/logs
mkdir -p $(pwd)/logs/batch
batchDir=${mainDir}/logs/batch

log=${batchDir}/${timeStamp}.log

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$log 2>&1

echo Logs:$log
echo STARTING at $(date)
git rev-parse HEAD

run_multiple_times(){
    i=0
    while [ $i -lt ${times} ]
    do
        i=$((i+1))
        port=$(($baseport+$i*10))
        bash -x run_fuzzing.sh ${port} ${tool} ${service} ${version}
    done
}

clear_states(){
    sudo docker stop gn-mongo
    sudo docker stop mongodb
    sudo docker stop mysql
    sudo docker stop mysqldb
    sudo docker rm gn-mongo
    sudo docker rm mongodb
    sudo docker rm mysql
    sudo docker rm mysqldb

    sudo fuser -k 27018/tcp
    sudo fuser -k 8080/tcp
    tmux kill-server
}

clear_states
bash -x vm_setup.sh
bash -x restgo_setup.sh
bash -x compile_one.sh $service $version
if [[ $version == "11" ]]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
else
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
fi
run_multiple_times

echo END at $(date)

