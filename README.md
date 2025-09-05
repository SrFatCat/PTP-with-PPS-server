# LuckFox Config
## Подготовка toolchain

1. Скопировать и распаковать драйвер из [вики](https://wiki.luckfox.com/zh/Luckfox-Pico-Plus-Mini/Flash-image) по [ссылке](https://files.luckfox.com/wiki/Omni3576/TOOLS/DriverAssitant_v5.13.zip) или [сохраненный](/DriverAssitant_v5.12.zip)
2. Скопировать и распаковать загрузчик образа на SPI-flash SocToolKit из [вики](https://wiki.luckfox.com/zh/Luckfox-Pico-Plus-Mini/Flash-image) по [ссылке](https://files.luckfox.com/wiki/Luckfox-Pico/Software/SocToolKit_v1.98_20240705_01_win.zip)
3. После установки драйвера и запуска Загрузчика выбрать `RV1103` (однократно), нажать на Лисе кнопку <kbd>BOOT</kbd>, только после этого подключив ее к USB: (в Загрузчике в поле выбора USB должно пояиться `Maskroom 1хх`).
4. Нажать <kbd>Search Path</kbd> и выбрать папку с образом, где лежат файлы download.bin, *.img, **env.img**, выбрать все файлы и нажать <kbd>Download<kbd>
   <details><summary>Иллюстрации</summary>
    
   ![](/toolkit1.png)
 
   ![](/toolkit2.png)
   </details>

5. При частичном обновлении образа, к примеру только пользовательской части или пользовательских файлов, выбирать не все файлы, а только `Download.bin` и `rootfs`.
6. При наличии одного файла образа (??) - выбирать только <kbd>Firmware...</kbd> и <kbd>Upgrade</kbd>
   <details><summary>Иллюстрации</summary>

    ![](/toolkit3.png)
    </details>

 ## Установка SDK 
Рекомендуется Ubuntu 22.04

```bash
sudo apt install -y git ssh make gcc gcc-multilib g++-multilib module-assistant expect g++ gawk texinfo libssl-dev bison flex fakeroot cmake unzip gperf autoconf device-tree-compiler libncurses5-dev pkg-config bc python-is-python3 passwd openssl openssh-server openssh-client vim file cpio rsync
```

   * GitHub
      ```
      git clone https://github.com/LuckfoxTECH/luckfox-pico.git
      ```

   * Gitee (китайцы ***рекомендуют***)
      ```
      git clone https://gitee.com/LuckfoxTECH/luckfox-pico.git
      ```
Если SDK устанавливается на WSL2, то для правильного запуска необходимо из путей убирать пробелы (осуществлять запуск например не через `build.sh`, а через [start.sh](/start.sh)

* Порядок полной сборки
  ```bash
  #./start.sh --help # помощь
  ./start.sh lunch # Однократно для выбора платы
  #./start.sh clean # если уже поковырялись, а надо все пересобрать
  ./start.sh
  ```

  Образ будет храниться по адресу `IMAGE/IPC_SPI_NAND_BUILDROOT_RV1103_LUCKFOX_PICO_PLUS_20250518.2049_RELEASE_TEST`

* Сборка только после выборы / изменения приложений 
  ```bash
  ./start.sh buildrootconfig # Для поиска приложений в псевдоGUI - нажимать /
  ./start.sh clean rootfs
  ./start.sh
  ```

* Сборка после добавления / изменения пользовательских файлов
  ```bash
  ./start firmware
  ```

  Образ будет храниться по адресу `/output/image` и для загрузки своих файлов нужен только `rootfs.img`

  <details><summary>Добавление своих файлов</summary>

  В папку SDK `project/cfg/BoardConfig_IPC/overlay` добавить свою подпапку `overlay-bogdan` и там разместить дерево с необходимыми файлами
  ```
  # например
  project/cfg/BoardConfig_IPC/overlay/overlay-bogdan/
  └── etc
      ├── samba
      │   ├── smb.conf
      │   └── smbpasswd
      ├── shadow
      └── ssh
          └── sshd_config
  ```

  В файле `project/cfg/BoardConfig_IPC/BoardConfig-<boardconfig>-IPS.mk` (boardconfig=SPI_NAND-Buildroot-RV1103_Luckfox_Pico_Plus) найти строчку `export RK_POST_OVERLAY="..."` и в конец добавить ` overlay-bogdan`
   </details>

## Настройка образа под задачи

### Static IP
<details><summary>В файле <code>overlay-bogdan/etc/init.d/S9Aeth0_staticip</code> под катом ручные</summary>

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
</details>       

### Часовой пояс

<details>
  <summary>Свернуто в файл <code>overlay-bogdan/etc/profile.d/msk-time.sh</code> </summary>
        
```
nano /etc/profile
```

```
export TZ=CST-3
```
        
</details>

### GPSd
<details>
 <summary><b><u>Распиновка</u></b></summary>
 
![](/luckfox-pinout.png)

|LuckFox|GPS|
|---|---|
|PIN36|	VCC|
|PIN8|	GND|
|PIN7|	RX|
|PIN6|	TX|
|PIN9|	PPS|

</details>


<details>
 <summary>Настройки файла <code>overlay-bogdan/etc/init.d/S50gpsd</code></summary>
        
Замена `DEVICES="/dev/ttyS1"` на `DEVICES="/dev/ttyS4 -G"`
        
</details>

<details>
 <summary>Создание симлинк gps0 через <code>overlay-bogdan/lib/udev/rules.d/80-gps-to-ntp.rules</code></summary>

`KERNEL=="ttyS4", SUBSYSTEM=="tty", DRIVER=="", SYMLINK+="gps0", MODE="0666"`

</details>

~~Скорость порта ttyS4 контроллирует `overlay-bogdan/etc/init.d/S99sttyS4config`~~<br />
Скорость порта в `gpsd` устанавливается ключем `-s`, в `ntp.conf` через `mode #+80` 

### NTPD

Следует посмотреть про `refclock_ppsapi: time_pps_create: Operation not supported` [здесь](https://forums.raspberrypi.com/viewtopic.php?t=375435) - создание символической ссылки /dev/gpspps0 на pps0 <br/>
[Generic NMEA GPS Receiver](https://www.eecis.udel.edu/~mills/ntp/html/drivers/driver20.html) про настройки baudrate и различные fudge факторы <br />

<details>
 <summary>Текущие настройки <code>overlay-bogdan/etc/ntp.conf</code></summary>
        
```
# gps0 source
server 127.127.20.0 mode 24 prefer
fudge 127.127.20.0 flag1 1

# pps0 source
server  127.127.22.0    minpoll 4
fudge   127.127.22.0    flag3 1

```
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

---
`ldattach pps /dev/ttyS0` [здесь](https://www.crc.id.au/2016/09/24/adding-a-pps-source-to-ntpd/) подробности
</details>
