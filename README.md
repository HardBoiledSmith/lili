# Introduction

Lili is a Vagrant provisioning script for [Johanna](https://github.com/hardboiledsmith/johanna) and [Raynor](https://github.com/hardboiledsmith/raynor).

# Environments

	Max OS X                        : 10.12.6
	VirtualBox                      : 5.1.28
	Vagrant                         : 1.9.7

# How To Play

1. install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).
1. `vagrant up`
1. after finishing Vagrant VM deployment, `vagrant ssh`, `ssh root@dv-lili.hbsmith.io` or `ssh root@192.168.100.100`
1. the Johanna and Raynor code is located in `/opt'
1. and you can use `raynor` from `http://dv-lili.hbsmith.io/dashboard/` or `http://192.168.100.100/dashboard/`
