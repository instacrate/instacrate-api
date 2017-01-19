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

	echo "{$red}sudo cp "$devServiceFileName" "$destinationPath$devServiceName"{$end}"
	sudo cp "$devServiceFileName" "$destinationPath$devServiceName"

	echo "{$red}sudo chmod 664 "$destinationPath$devServiceName"{$end}"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "{$red}systemctl daemon-reload{$end}"
	systemctl daemon-reload

	echo "{$red}systemctl restart "$devServiceName"{$end}"
	systemctl restart "$devServiceName"
}

reset_production_server() {

	prodServiceFileName="instacrated.service.txt"
	prodServiceName="instacrated.service"

	echo "{$red}sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"{$end}"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "{$red}sudo chmod 664 "$destinationPath$prodServiceName"{$end}"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "{$red}systemctl daemon-reload{$end}"
	systemctl daemon-reload

	echo "{$red}systemctl restart "$prodServiceName"{$end}"
	systemctl restart "$prodServiceName"
}

echo "{$red}git pull origin master{$end}"
git pull origin master

echo "{$red}vapor build --release=true{$end}"
vapor build --release=true

echo "{$red}sudo systemctl restart instacrated.service{$end}"
sudo systemctl restart instacrated.service

echo "{$red}sudo systemctl restart dev-instacrated.service{$end}"
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
