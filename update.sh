reset_development_server() {

	devServiceFileName="dev-instacrated.service.txt"
	devServiceName="dev-instacrated.service"

	destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp "$devServiceFileName" "$destinationPath$devServiceName""
	sudo cp "$devServiceFileName" "$destinationPath$devServiceName"

	echo "\n>>>> sudo chmod 664 "$destinationPath$devServiceName""
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> systemctl daemon-reload"
	systemctl daemon-reload

	echo "\n>>>> systemctl restart "$devServiceName""
	systemctl restart "$devServiceName"
}

reset_production_server() {

	prodServiceFileName="instacrated.service.txt"
	prodServiceName="instacrated.service"

	echo "\n>>>> sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName""
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 "$destinationPath$prodServiceName""
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> systemctl daemon-reload"
	systemctl daemon-reload

	echo "\n>>>> systemctl restart "$prodServiceName""
	systemctl restart "$prodServiceName"
}

echo "\n>>>> git pull origin master"
git pull origin master

if [[ $(git diff --name-only HEAD~1 HEAD 'update.sh') ]]; then
	# re-run the update script because it was just updated in the git pull
	exec 'sh update.sh'
fi

if [[ $(git diff --name-only HEAD~1 HEAD nginx/) ]]; then
	echo "\nsudo cp -ru nginx/* /etc/nginx/"
	sudo cp -ru nginx/* /etc/nginx/
fi

echo "\n>>>> vapor build --release=true --fetch=false"
vapor build --release=true --fetch=false

echo "\n>>>> sudo systemctl restart instacrated.service"
sudo systemctl restart instacrated.service

echo "\n>>>> sudo systemctl restart dev-instacrated.service"
sudo systemctl restart dev-instacrated.service

if [[ $(git diff --name-only instacrated.service.txt) ]]; then
    echo "\n>>>> Detected changes in production server configuration files!"
	reset_production_server
fi

if [[ $(git diff --name-only dev-instacrated.service.txt) ]]; then
	echo "\n>>>> Detected changes in development server configuration files!"
	reset_development_server
fi
