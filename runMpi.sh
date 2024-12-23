#!/bin/bash -x

machine=$1
HOSTS=$2
HOSTS_SIZE=$3
isFSX=$4
isS3=$5

echo machine=$machine
echo HOSTS=$HOSTS
echo HOSTS_SIZE=${HOSTS_SIZE}
echo isFSX=${isFSX}
echo isS3=${isS3}
if [[ "$isFSX" == "true" ]]; then
    ssh ec2-user@$machine -i ~/.ssh/id_ed25519 << EOF
    cd codigo/io500
    tmux new-session -d -s io500_session_2 "PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:/home/ec2-user/codigo/io500/lib HOSTS=$HOSTS HOSTS_SIZE=${HOSTS_SIZE} ./io500.sh config-all.ini 2>errorLog.log;"
EOF
else
    ssh ec2-user@$machine -i ~/.ssh/id_ed25519 << EOF
    cd codigo/io500
    tmux new-session -d -s io500_session_2 "PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:/home/ec2-user/codigo/io500/lib HOSTS=$HOSTS HOSTS_SIZE=${HOSTS_SIZE} ./io500.sh ./contrib/s3/config-s3.ini 2>errorLog.log;"
EOF
fi
echo $machine >> THAT_MACHINE.LOG
