#!/usr/bin/env bash
set -e

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

# create swap space to handle memory hungry processes
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile	none	swap	sw	0	0" >> /etc/fstab

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

cp /vagrant/id_rsa ~/.ssh/
cp -R /vagrant/configuration ~/
cp -R /vagrant/debian_packages ~/
cp -R /vagrant/python_packages ~/

echo "root:1234qwer" | chpasswd

sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
service ssh restart

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

cp /etc/apt/sources.list /etc/apt/sources.list.backup
sed -i -e '/^deb/s#http://.*archive.ubuntu.com/ubuntu#http://kr.archive.ubuntu.com/ubuntu#' -e '/^deb/s#http://.*security.ubuntu.com/ubuntu#http://kr.archive.ubuntu.com/ubuntu#' /etc/apt/sources.list

apt-get -y clean
apt-get -y update

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

export DEBIAN_FRONTEND=noninteractive

apt-get -y install gdebi-core

cd ~/debian_packages
gdebi -n -q build-essential_12.1ubuntu2_amd64.deb
gdebi -n -q g++-5_5.4.0-6ubuntu1-16.04.2_amd64.deb
gdebi -n -q libpython3.5-dev_3.5.2-2-16.04_amd64.deb
gdebi -n -q git_2.7.4-0ubuntu1_amd64.deb
gdebi -n -q nginx_1.10.0-0ubuntu0.16.04.4_all.deb
gdebi -n -q python3-pip_8.1.1-2ubuntu0.2_all.deb
gdebi -n -q python3-setuptools_20.7.0-1_all.deb
gdebi -n -q zlib1g_1.2.8.dfsg-2ubuntu4_amd64.deb
gdebi -n -q erlang-redis-client_1.0.8-1_amd64.deb

cd ~/python_packages
pip3 install --upgrade pip
pip3 install Django-1.10.1.tar.gz
pip3 install uwsgi-2.0.13.1.tar.gz
pip3 install awscli-1.10.67.tar.gz
pip3 install awsebcli-3.7.8.tar.gz
pip3 install colorama-0.3.7.tar.gz
pip3 install PyYAML-3.12.tar.gz
pip3 install Twisted-16.4.1.tar.bz2
pip3 install arrow-0.8.0.tar.gz
pip3 install asgi_redis-0.14.1.tar.gz
pip3 install asgiref-0.14.0.tar.gz
pip3 install autobahn-0.16.0.tar.gz
pip3 install blessed-1.14.1.tar.gz
pip3 install botocore-1.4.58.tar.gz
pip3 install cement-2.10.2.tar.gz
pip3 install channels-0.17.2.tar.gz
pip3 install daphne-0.15.0.tar.gz
pip3 install django-compat-1.0.13.tar.gz
pip3 install docker-py-1.10.3.tar.gz
pip3 install dockerpty-0.4.1.tar.gz
pip3 install docopt-0.6.2.tar.gz
pip3 install docutils-0.12.tar.gz
pip3 install future-0.15.2.tar.gz
pip3 install jmespath-0.9.0.tar.gz
pip3 install msgpack-python-0.4.8.tar.gz
pip3 install pathspec-0.5.0.tar.gz
pip3 install python-dateutil-2.5.3.tar.gz
pip3 install redis-2.10.5.tar.gz
pip3 install requests-2.11.1.tar.gz
pip3 install semantic_version-2.6.0.tar.gz
pip3 install six-1.10.0.tar.gz
pip3 install texttable-0.8.5.tar.gz
pip3 install txaio-2.5.1.tar.gz
pip3 install wcwidth-0.1.7.tar.gz
pip3 install websocket_client-0.37.0.tar.gz
pip3 install zope.interface-4.3.2.tar.gz

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

mkdir -p /etc/raynor
mkdir -p /etc/uwsgi
mkdir -p /var/log/raynor
mkdir -p /var/log/uwsgi

PP=~/configuration
cp --backup ${PP}/etc/init.d/raynor                  /etc/init.d/raynor
cp --backup ${PP}/etc/nginx/conf.d/raynor.conf       /etc/nginx/conf.d/raynor.conf
cp --backup ${PP}/etc/nginx/nginx.conf               /etc/nginx/nginx.conf
cp --backup ${PP}/etc/nginx/sites-enabled/default    /etc/nginx/sites-enabled/default
cp --backup ${PP}/etc/uwsgi/raynor.ini               /etc/uwsgi/raynor.ini

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

cd /opt

for i in `seq 1 10`;
do
	echo 'Git clone try count: '${i}

	# Non interactive git clone (ssh fingerprint prompt)
	ssh-keyscan github.com > ~/.ssh/known_hosts || true
	git clone git@github.com:addnull/johanna.git || true
	if [ -d /opt/johanna ]; then
		break
	fi

	sleep 3
done

cd /opt/johanna
cp config.json.sample config.json

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

cd /opt

for i in `seq 1 10`;
do
	echo 'Git clone try count: '${i}

	# Non interactive git clone (ssh fingerprint prompt)
	ssh-keyscan github.com > ~/.ssh/known_hosts || true
	git clone git@github.com:addnull/raynor.git || true
	if [ -d /opt/raynor ]; then
		break
	fi

	sleep 3
done

cd /opt/raynor
./manage.py collectstatic --noinput

echo -e "##############################\nLINE NUMBER: "$LINENO"\n##############################"

update-rc.d raynor defaults

reboot
