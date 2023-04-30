project=$1
version=$2

timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/compile_logs

currentDir=$(pwd)
mainDir=$(pwd)/REST_Go
logDir=${mainDir}/logs/compile_logs
evo_jdk8=${mainDir}/services/evo_jdk8
services_jdk8=${mainDir}/services/jdk8
services_jdk11=${mainDir}/services/jdk11

projects_jdk8=("spring-boot-sample-app" "erc20-rest-service" "genome-nexus" "person-controller" "rest-study" "user-management" "problem-controller" "spring-batch-rest")
projects_jdk11=("cwa-verification" "market" "project-tracking-system" ) #("market")
projects_jdk8_evo=("ncs" "news" "scs" "features-service" "languagetool" "proxyprint" "restcountries" "scout-api" "ocvn") #"ocvn"

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$logDir/$timeStamp.log 2>&1

echo Logs:$logDir
echo STARTING at $(date)
git rev-parse HEAD


compile_evo_jdk8(){
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH

    cd $evo_jdk8
    mvn install -DskipTests
    mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
}

compile_jdk8(){
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH

    cd $services_jdk8
    cd $project
    if [[ $project == "erc20-rest-service" ]]; then
        chmod +x gradlew && ./gradlew build
        cd $mainDir
        tmux new -s ether
        
    else
    mvn install -DskipTests -DskipITs
    mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
    fi
}

compile_jdk11(){
    export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
    
    cd $services_jdk11
    cd $project
    mvn install -DskipTests
    mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
}

cd $mainDir

if [[ $version == "11" ]]; then
    compile_jdk11
fi
if [[ $version == "8" ]]; then
    compile_jdk8
fi
if [[ $version == "evo8" ]]; then
    compile_evo_jdk8
fi
cd $currentDir

echo ENDING at $(date)
