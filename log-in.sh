#!/bin/bash

machine=$1
machine=$(cat THAT_MACHINE.LOG)
ssh ec2-user@$machine -i ~/.ssh/id_ed25519 -o ServerAliveInterval=5 -o ServerAliveCountMax=1
