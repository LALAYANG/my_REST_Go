current=$(pwd)
restgo=$(pwd)/REST_Go
replace=$(pwd)/replace_REST_Go

cp ${replace}/* $restgo

cd $restgo
sudo apt-get install tmux -y
sudo docker pull genomenexus/gn-mongo
sudo docker pull mongo
sudo docker pull mysql
sudo apt install zip -y

######Testing Tools#####
# Install Dredd 14.1.0
sudo npm install -g dredd

# Install EvoMaster 1.3.0
wget https://github.com/EMResearch/EvoMaster/releases/download/v1.3.0/evomaster.jar.zip
unzip evomaster.jar.zip
rm evomaster.jar.zip

# Install Schemathesis 3.11.6
. ./venv/bin/activate && pip install schemathesis

# Install APIFuzzer 0.9.11
. ./venv/bin/activate && cd APIFuzzer && pip install .
cd $restgo

# Install RESTler 8.3.0
. ./venv/bin/activate \
&& wget https://github.com/microsoft/restler-fuzzer/archive/refs/tags/v8.3.0.tar.gz \
&& tar -xvf v8.3.0.tar.gz \
&& rm v8.3.0.tar.gz \
&& mv restler-fuzzer-8.3.0 restler \
&& cd restler \
&& mkdir restler_bin \
&& python ./build-restler.py --dest_dir ./restler_bin
cd $restgo

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Install RESTest 1.2.0 (need to install dependency as well)
cd ./RESTest && sh ./scripts/install_dependencies.sh && mvn clean install -DskipTests
cd $restgo

# Install bBOXRT (Commit e5d329133d51aa75cd39209590cac7046d0640b1)
cd ./bBOXRT && mvn install -DskipTests
cd $restgo

# Install RestTestGen
cd ./RestTestGen && chmod +x gradlew && ./gradlew jar
cd $restgo

wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.7/org.jacoco.agent-0.8.7-runtime.jar
wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.7/org.jacoco.cli-0.8.7-nodeps.jar

cd $current