#!/bin/bash

machine=$1

ssh ec2-user@$machine -i ~/.ssh/id_ed25519
