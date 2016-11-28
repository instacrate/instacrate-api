#!/usr/bin/env bash

devServiceFileName="dev-instacrated.service.txt"
devServiceName="dev-instacrated.service"

prodServiceFileName="instacrated.service.txt"
prodServiceName="instacrated.service"

destinationPath="/etc/systemd/system/"

sudo cp "$devServiceFileName" "$destinationPath$devServiceName"
sudo chmod 664 "$destinationPath$devServiceName"

sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"
sudo chmod 664 "$destinationPath$prodServiceName"

systemctl daemon-reload

systemctl start "$devServiceName"
systemctl start "$prodServiceName"
