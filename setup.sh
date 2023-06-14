#!/bin/bash
ip_addr="$1"
echo "  Start  "
# 测试网络
echo -e "\033[32 Network test...\033[0m"
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

ping -c 4 mirrors.aliyun.com 
if [ $? -eq 0 ]; then
  yum -y install wget  
else
  echo " Network test failed. Please check your connection and try again. "
  exit 1
fi

echo -e "\033[32 Configuring Alibaba Cloud mirror and EPEL repository...\033[0m"
# 备份本地官方源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
#下载阿里源
wget -q -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
#备份epel源
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
#下载阿里epel源
wget -q -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#生成缓存
yum clean all && yum makecache  
#查看当前源
yum repolist

#安装常用工具
yum provides '*/applydeltarpm'  
yum group install -y  "Development Tools"
yum -y install vim gcc gcc-c++ zlib-devel curl-devel vim-enhanced net-tools screen
yum -y update

#安装docker
echo -e "\033[32 Installing Docker CE...\033[0m"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
rpm --import http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-7
yum install -y docker-ce
#开启docker
systemctl start docker
systemctl enable docker
#docker换源
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ah2l9a2i.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

#安装docker-compose
echo -e "\033[32 Installing Docker Compose...\033[0m"
#下载地址：https://github.com/docker/compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose  
chmod +x /usr/local/bin/docker-compose
docker-compose version
systemctl restart docker

#安装java
echo -e "\033[32 Installing Java 8...\033[0m"
sudo yum install -y java-1.8.0-openjdk-devel
java -version

#安装Maven
echo -e "\033[32 Installing Maven 3.8.3...\033[0m"
curl -q -O /opt/apache-maven-3.8.3-bin.tar.gz https://archive.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
sudo tar -xzvf /opt/apache-maven-3.8.3-bin.tar.gz -C /opt
sudo tee /etc/profile.d/maven.sh <<-'EOF'
export M2_HOME=/opt/apache-maven-3.8.3
export PATH=${M2_HOME}/bin:${PATH}
EOF
sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
sudo sed -i '/<mirrors>/a\  <mirror>\n    <id>alimaven<\/id>\n    <name>aliyun maven<\/name>\n    <url>https:\/\/maven.aliyun.com\/repository\/central\/<\/url>\n    <mirrorOf>central<\/mirrorOf>\n  <\/mirror>' /opt/apache-maven-3.8.3/conf/settings.xml

#配置网卡
echo "\033[32 Configuring IP address and DNS...\033[0m"
sed -i "s/^IPADDR=.*/IPADDR=$ip_addr/" /etc/sysconfig/network-scripts/ifcfg-ens33
if grep -q '^DNS1=' /etc/sysconfig/network-scripts/ifcfg-ens33; then
  sed -i 's/^DNS1=.*/DNS1=8.8.8.8/' /etc/sysconfig/network-scripts/ifcfg-ens33
else
  echo "DNS1=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-ens33
fi

if grep -q '^DNS2=' /etc/sysconfig/network-scripts/ifcfg-ens33; then
  sed -i 's/^DNS2=.*/DNS2=114.114.114.114/' /etc/sysconfig/network-scripts/ifcfg-ens33
else
  echo "DNS2=114.114.114.114" >> /etc/sysconfig/network-scripts/ifcfg-ens33
fi
echo -e "\033[32 $ip_addr \033[0m"
echo -e "\033[32 Setup complete. Enjoy your new VM! \033[0m"
systemctl restart network.service

