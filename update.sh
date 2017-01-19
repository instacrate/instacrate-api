red=$'\e[1;31m'
gray=$'\e[90m'
grn=$'\e[1;32m'
end=$'\e[0m'
lgrn=$'\e[1;92m'
yel=$'\e[33m'

reset_development_server() {

	devServiceFileName="dev-instacrated.service.txt"
	devServiceName="dev-instacrated.service"

	destinationPath="/etc/systemd/system/"

	echo "sudo cp "$devServiceFileName" "$destinationPath$devServiceName""
	sudo cp "$devServiceFileName" "$destinationPath$devServiceName"

	echo "sudo chmod 664 "$destinationPath$devServiceName""
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "systemctl daemon-reload"
	systemctl daemon-reload

	echo "systemctl restart "$devServiceName""
	systemctl restart "$devServiceName"
}

reset_production_server() {

	prodServiceFileName="instacrated.service.txt"
	prodServiceName="instacrated.service"

	echo "sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName""
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "sudo chmod 664 "$destinationPath$prodServiceName""
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "systemctl daemon-reload"
	systemctl daemon-reload

	echo "systemctl restart "$prodServiceName""
	systemctl restart "$prodServiceName"
}

echo "git pull origin master"
git pull origin master

echo "vapor build --release=true"
vapor build --release=true

echo "sudo systemctl restart instacrated.service"
sudo systemctl restart instacrated.service

echo "sudo systemctl restart dev-instacrated.service"
sudo systemctl restart dev-instacrated.service

changes=$(git diff --name-only HEAD~1 HEAD)

if grep '^instacrated.service.txt$' changes; then
	echo "Detected changes in production server configuration files!"
	reset_production_server
fi

if grep '^dev-instacrated.service.txt$' changes; then
	echo "Detected changes in development server configuration files!"
	reset_development_server
fi
