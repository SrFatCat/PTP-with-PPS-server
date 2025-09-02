# LuckFox Config
## Создание пользователя
```
adduser luxfox -G wheel
```

## Static IP

```
cd /etc/init.d
mv S99usb0config S90usb0config 
mv S99_auto_reboot S90_auto_reboot
```

```nano S99eth0_staticip```


```
#!/bin/sh

case $1 in
        start)
                killall udhcpc
                ifconfig eth0 192.168.0.200 netmask 255.255.255.0
                route add default gw 192.168.0.1
                echo "nameserver 8.8.8.8" > /etc/resolv.conf

                ;;
        stop)
                ;;
        *)
                exit 1
                ;;
esac
```

```chmod +x S99eth0_staticip ```

Другой способ убить `udhcpc` - в файле `/usr/share/udhcpc/default.script` вставить `exit` в начало

## Часовой пояс

<details>
  <summary>Свернуто в файл <code>overlay-bogdan/etc/profile.d/msk-time.sh</code> </summary>
        
```
nano /etc/profile
```

```
export TZ=CST-3
```
        
</details>

## GPSd

![](/luckfox-pinout.png)

|LuckFox|GPS|
|---|---|
|PIN36|	VCC|
|PIN8|	GND|
|PIN7|	RX|
|PIN6|	TX|
|PIN9|	PPS|

<details>
 <summary>Настройки файла <code>overlay-bogdan/etc/init.d/S50gpsd</code></summary>
        
Замена `DEVICES="/dev/ttyS1"` на `DEVICES="/dev/ttyS4 -G"`
        
</details>

<details>
 <summary>Создание симлинк gps0 через <code>overlay-bogdan/lib/udev/rules.d/80-gps-to-ntp.rules</code></summary>

`KERNEL=="ttyS4", SUBSYSTEM=="tty", DRIVER=="", SYMLINK+="gps0", MODE="0666"`

</details>




<details>


# PTP-with-PPS-server


## [DESCRIPTION](https://manpages.debian.org/stretch/pps-tools/ppswatch.8.en.html)


### ppstest: PPSAPI interface tester
### ppsldisc: setup correct RS232 line discipline
### ppswatch: continuously print PPS timestamps
### ppsctl: PPS device manager
### ppsfind: find pps device by name

---
ppscheck - tool to check a serial port for PPS [DESCRIPTION](https://manpages.ubuntu.com/manpages/noble/man8/ppscheck.8.html)
</details>

---
`ldattach pps /dev/ttyS0` [здесь](https://www.crc.id.au/2016/09/24/adding-a-pps-source-to-ntpd/) подробности
