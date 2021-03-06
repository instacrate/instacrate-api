#!/usr/bin/env bash

reset_development_server() {

	local devServiceFileName="dev-instacrated.service.txt"
	local devServiceName="dev-instacrated.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $devServiceFileName $destinationPath$devServiceName"
	sudo cp "$devServiceFileName" "$destinationPath$devServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$devServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload

	echo "\n>>>> sudo systemctl restart $devServiceName"
	sudo systemctl restart "$devServiceName"
}

reset_production_server() {

	local prodServiceFileName="instacrated.service.txt"
	local prodServiceName="instacrated.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload

	echo "\n>>>> sudo systemctl restart $prodServiceName"
	sudo systemctl restart "$prodServiceName"
}

echo "\n>>>> git pull origin"
git pull origin

if [ "$(git diff --name-only HEAD~ HEAD -- nginx/)" ]; then
	echo "\n>>>> sudo cp -ru nginx/* /etc/nginx/"
	sudo cp -ru nginx/* /etc/nginx/
fi

echo "\n>>>> vapor build --release=true --fetch=false"
vapor build --release=true --fetch=false --verbose

if [ "$(git diff --name-only HEAD~1 HEAD -- instacrated.service.txt)" ]; then
    echo "\n>>>> Detected changes in production server configuration files!"
	reset_production_server
fi

if [ "$(git diff --name-only HEAD~1 HEAD -- dev-instacrated.service.txt)" ]; then
	echo "\n>>>> Detected changes in development server configuration files!"
	reset_development_server
fi

echo "\n>>>> sudo systemctl restart instacrated.service"
sudo systemctl restart instacrated.service

echo "\n>>>> sudo systemctl restart dev-instacrated.service"
sudo systemctl restart dev-instacrated.service