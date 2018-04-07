#!/bin/bash
mkdir tiny
mkdir nesC
cd nesC

sudo dpkg --configure -a

sudo apt-get install git make automake emacs gperf bison flex default-jdk python2.7-dev python-minimal g++

git clone git://github.com/tinyos/nesc.git

cd nesc
./Bootstrap
./configure

sudo make
sudo make install
#nesC is now installed

cd ..
cd ..
cd tiny
git clone git://github.com/tinyos/tinyos-main.git
cd tinyos-main/tools
./Bootstrap
./configure
sudo make
sudo make install
#tinyos is now installed

cd ..
cd apps
cd Blink
sudo make micaz sim && exit #if this succeeds, no further action is required

cd ..
cd ..
cd tools
./Bootstrap
./configure
sudo make
sudo make install

cd ..
cd ..
cd apps
cd Blink
sudo make micaz sim && exit #if this succeeds, no further action is required
