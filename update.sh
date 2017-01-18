cd Packages/Stripe-0.0.10
git pull origin master
cd ..
git pull origin master
vapor build
sudo systemctl restart instacrated.service
sudo systemctl restart dev-instacrated.service
