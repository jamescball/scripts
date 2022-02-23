#! /bin/bash -
echo "Starting Install..."
sudo apt install curl
echo "Installing ROS + Catkin..."
curl -sL https://raw.githubusercontent.com/jamescball/scripts/main/ROS_INSTALLER.sh | bash
curl -sL https://raw.githubusercontent.com/jamescball/scripts/main/ROS_WORKSPACE.sh | bash
echo "Installing Arduino..."
curl -sL https://raw.githubusercontent.com/jamescball/scripts/main/ARDUINO_INSTALL.sh | bash
echo "Checking for updates"
sudo apt-get update && sudo apt-get upgrade
echo "Reboot required to finish install."
read -p "Press ENTER to continue."
