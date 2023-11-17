#!/bin/bash

machine=$1
HOSTS=$2
echo machine=$machine
echo HOSTS=$HOSTS

ssh ec2-user@$machine -i ~/.ssh/id_ed25519 "cd codigo/io500; echo inside HOSTS=$HOSTS ;PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin LD_LIBRARY_PATH=/usr/lib64/openmpi/lib HOSTS=$HOSTS ./io500.sh config-minimal.ini"
