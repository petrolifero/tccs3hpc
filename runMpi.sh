#!/bin/bash -x

machine=$1
HOSTS=$2
HOSTS_SIZE=$3
echo machine=$machine
echo HOSTS=$HOSTS
echo HOSTS_SIZE=${HOSTS_SIZE}
#ssh ec2-user@$machine -i ~/.ssh/id_ed25519 "cd codigo/io500; echo inside HOSTS=$HOSTS ; tmux new-session -d -s io500_session 'PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:/home/ec2-user/codigo/io500/lib HOSTS=$HOSTS HOSTS_SIZE=${HOSTS_SIZE} ./io500.sh config-scc-2.ini'"

ssh ec2-user@$machine -i ~/.ssh/id_ed25519 "cd codigo/io500; echo inside HOSTS=$HOSTS ; PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:/home/ec2-user/codigo/io500/lib HOSTS=$HOSTS HOSTS_SIZE=${HOSTS_SIZE} ./io500.sh config-all.ini"

echo $machine > THAT_MACHINE.LOG
