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

sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
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
gdebi -n -q g++-4.8_4.8.4-2ubuntu1-14.04.3_amd64.deb
gdebi -n -q libpython2.7-dev_2.7.6-8ubuntu0.2_amd64.deb
gdebi -n -q git_1.9.1-1ubuntu0.3_amd64.deb
gdebi -n -q nginx_1.4.6-1ubuntu3.5_all.deb
gdebi -n -q python-pip_1.5.4-1ubuntu4_all.deb
gdebi -n -q zlib1g-dev_1.2.8.dfsg-1ubuntu1_amd64.deb

cd ~/python_packages
pip install Django-1.10.1.tar.gz
pip install uwsgi-2.0.13.1.tar.gz

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
pip install -r requirements.txt
cp env.py.sample env.py

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
