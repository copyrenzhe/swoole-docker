#!/bin/sh
set -e

env=`env | grep APP_ENV | awk -F "=" '{print $2}'`

if [ -z $env ];then
    env="local"
fi

echo "export APP_ENV=$env" >> /etc/profile
echo "export QD_TSF_ENV=$env" >> /etc/profile

source /etc/profile

exit 0