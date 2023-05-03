sudo apt-get update

sudo apt update
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install git-all -y

sudo apt install python3-tk -y

# Install Common Utilities
sudo apt-get install -y software-properties-common \
unzip wget gcc git vim libcurl4-nss-dev tmux git

# Install Java8
sudo apt-get install -y openjdk-8-jdk
sudo apt-get install -y maven gradle
sudo apt-get install -y openjdk-11-jdk

# Install Python3
sudo apt-get install -y python3-pip python3-virtualenv

pip3 install BeautifulSoup4
pip3 install jsonlines
pip3 install openai

pip install BeautifulSoup4
pip install jsonlines
pip install openai

# Install NodeJS and NPM
sudo apt-get install -y nodejs npm

# Install Docker
sudo apt-get install -y docker.io

# Install Dotnet SDK 5.0
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
&& sudo dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb \
&& sudo apt-get update \
&& sudo apt-get install -y apt-transport-https \
&& sudo apt-get install -y dotnet-sdk-5.0

# Install Ethereum
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update && sudo apt-get install -y ethereum

sudo apt-get install emacs
git clone https://github.com/codingsoo/REST_Go
cd REST_Go
git checkout d54ead3c2d69bf75eedf15d7b3083836ec5fd80f
sed -i 's#<goal>build-info</goal>#<!--&-->#g' services/jdk8/spring-boot-sample-app/pom.xml
virtualenv venv
cd ..
# sed -i -e '37,50s/cd /# cd /' -e 's;# cd ../genome-nexus;cd services/genome-nexus;' setup.sh
