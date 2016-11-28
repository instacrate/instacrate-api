#!/usr/bin/env bash

serviceFileName="instacrated.service.txt"
serviceName="instacrated.service"
servicePath="/etc/systemd/system/"

sudo cp "$serviceFileName" "$servicePath$serviceName"
sudo chmod 664 "$servicePath$serviceName"

systemctl daemon-reload
systemctl start "$serviceName"
