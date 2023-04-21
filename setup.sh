apt-get update
apt-get -y install openjdk-8-jdk

apt update
apt install -y  maven

apt update
apt install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install python3.8 -y

dnf install git-all 
apt install git-all -y


update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

update-alternatives  --set python3 /usr/bin/python3.8

apt install python3-tk -y
apt install python3-pip -y
pip3 install BeautifulSoup4
pip3 install jsonlines

apt-get install emacs
git clone https://github.com/codingsoo/REST_Go
cd REST_Go
git checkout d54ead3c2d69bf75eedf15d7b3083836ec5fd80f
sed -i -e '37,50s/cd /# cd /' -e 's;# cd ../genome-nexus;cd services/genome-nexus;' setup.sh
