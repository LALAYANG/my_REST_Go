timeStamp=$(echo -n $(date "+%Y-%m-%d %H:%M:%S") | shasum | cut -f 1 -d " ")

mkdir -p $(pwd)/REST_Go/logs
mkdir -p $(pwd)/REST_Go/logs/compile_logs

currentDir=$(pwd)
mainDir=$(pwd)/REST_Go
logDir=${mainDir}/logs/compile_logs
evo_jdk8=${mainDir}/services/evo_jdk8
services_jdk8=${mainDir}/services/jdk8
services_jdk11=${mainDir}/services/jdk11

projects_jdk8=("spring-boot-sample-app" "erc20-rest-service" "genome-nexus" "person-controller" "problem-controller" "rest-study" "user-management" ) #done: "problem-controller" "genome-nexus" "testing_security_development_enterprise_systems" "languagetool" 
projects_jdk11=("cwa-verification" "market" "project-tracking-system" ) #("market")
# projects_jdk8_evo=()

exec 3>&1 4>&2
trap $(exec 2>&4 1>&3) 0 1 2 3
exec 1>$logDir/$timeStamp.log 2>&1

echo Logs:$logDir
echo STARTING at $(date)

compile_jdk8(){
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH

    cd $evo_jdk8
    mvn clean install -DskipTests
    mvn dependency:build-classpath -Dmdep.outputFile=cp.txt

    cd $services_jdk8
    for project in ${projects_jdk8[@]}; 
    do
        cd $project
        mvn clean install -DskipTests
        mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
        cd ..
    done
}

compile_jdk11(){
    export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
    
    cd $services_jdk11
    for project in ${projects_jdk11[@]}; 
    do
        cd $project
        mvn clean install -DskipTests
        mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
        cd ..
    done
}

cd $mainDir
compile_jdk11
# compile_jdk8

cd $currentDir

echo ENDING at $(date)