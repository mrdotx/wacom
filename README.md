# wacom

configuration of the wacom tablet at startup and when connected to the usb port

## install udev rule and service

- cp 99-wacom.rules /etc/udev/rules.d/99-wacom.rules
- cp wacom.service $HOME/.config/systemd/user/wacom.service

## enable service

- systemctl --user enable wacom.service
