#!/bin/sh
[ -f /etc/init.d/S99usb0config ] && mv -v /etc/init.d/S99usb0config /etc/init.d/S90usb0config && echo "S99usb0config moved" || echo "S99usb0config NOT FOUND!"
[ -f /etc/init.d/S99_auto_reboot ] && mv -v /etc/init.d/S99_auto_reboot /etc/init.d/S90_auto_reboot && echo "S99_auto_reboot moved" || echo "S99_auto_reboot NOT FOUND!"
sed -i 's/^DEVICES=.*/DEVICES="\/dev\/ttyS4 \/dev\/pps0 -G -s 115200 -n"/' /etc/init.d/S50gpsd && echo "s50gpsd modifed" || echo "s50gpsd ERROR!"
[ -f /etc/init.d/S65ptpd2 ] && mv -v /etc/init.d/S65ptpd2 /etc/init.d/S99ptpd2 && echo "S65ptpd2 moved" || echo "S65ptpd2 NOT FOUND!"
sed -i 's/start-stop-daemon -S -q -x.*/start-stop-daemon -S -q -x \/usr\/sbin\/ptpd2 -- -M -i eth0 -f \/var\/log\/ptpd.log/' /etc/init.d/S99ptpd2 && echo "S99ptpd2 modifed" || echo "S99ptpd2 ERROR!"
[ -f /etc/init.d/S49ntp ] && [ -f /etc/init.d/S49ntpd ] && rm -f /etc/init.d/S49ntpd && echo "S49ntpd delete" || echo "S49ntp[d] the only ONE! "
read -p "[C]rony or [N]TPd [C]: " ans; [ -z "$ans" ] || [ "$ans" = "c" ] || [ "$ans" = "C" ] && chmod -x /etc/init.d/S49ntp || chmod -x /etc/init.d/S49chrony
reboot -f

