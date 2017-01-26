f() {
    errcode=$?
    echo "error $errorcode"
    echo "the command executing at the time of the error was"
    echo "$BASH_COMMAND"
    echo "on line ${BASH_LINENO[0]}"
    exit $errcode
}

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

trap f ERR

echo "\n>>>> git pull origin master"
git pull origin master

echo "\n>>>> vapor build --release=true --fetch=false"
vapor build --release=true --fetch=false

echo "\n>>>> sudo systemctl restart instacrated.service"
sudo systemctl restart instacrated.service

echo "\n>>>> sudo systemctl restart dev-instacrated.service"
sudo systemctl restart dev-instacrated.service

changes=$(git diff --name-only HEAD~1 HEAD)

if grep '^instacrated.service.txt$' "$changes"; then
	echo "\n>>>> Detected changes in production server configuration files!"
	reset_production_server
fi

if grep '^dev-instacrated.service.txt$' "$changes"; then
	echo "\n>>>> Detected changes in development server configuration files!"
	reset_development_server
fi
