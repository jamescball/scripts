#! /bin/bash -
sudo snap install arduino && sudo usermod -a -G dialout $USER && echo "SUBSYSTEM==\"usb\", MODE=\"0660\", GROUP=\"$(id -gn)\"" | sudo tee /etc/udev/rules.d/00-usb-permissions.rules udevadm control && arduino.pip install requests && echo "Please reboot to finish install"
