#!/usr/bin/env bash

serviceName="instacrated.service"
servicePath="/etc/systemd/system/"

cp "$serviceName" "$servicePath$serviceName"
chmod 664 "$servicePath$serviceName"