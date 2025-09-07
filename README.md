# LuckFox в качестве сервера точного времени и PTP сервера с синхронизацией GPS/PPS
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

## Редактирование DTS под включение ttS4 ttyS3 и KPPS

В SDK [в файл `sysdrv/source/kernel/arch/arm/boot/dts/rv1103g-luckfox-pico-plus.dts`](/rv1103g-luckfox-pico-plus.dts)
* в раздел `/{` после `compitable = ...` добавить
  ```
  pps {
  	compatible = "pps-gpio";
  	pinctrl-names = "default";
  	gpios = <&gpio1 RK_PD2 GPIO_ACTIVE_HIGH>;
  	status = "okay";
  };
  ```
  
* после этого в `/**********GPIO**********/`
  ```
  /**********GPIO**********/
  &pinctrl {
  	gpio1-pd2 {
  		gpio1_pd2:gpio1-pd2 {
  			rockchip,pins =	<2 RK_PD2 RK_FUNC_GPIO &pcfg_pull_none>;
  		};
  	};
  };
  ```
  
* затем найти `&uart4 {` и заменить `disable` на `okey`, после тоже самое сделать для `&uart3 {`
  ```
   &uart4 {
	   status = "okay";
	   pinctrl-names = "default";
	   pinctrl-0 = <&uart4m1_xfer>;
   };
  ```

Оригинальный [мануал](https://wiki.luckfox.com/Luckfox-Pico/Luckfox-Pico-UART#5-modifying-device-tree) по редактированию DTS

* отредактировать настройки ядра ./start.sh kernelconfig
   ```
   Device Drivers  --->
    <*> PPS support  --->
     <*>   PPS client using GPIO
   ```

* скомпилировать ядро по манулу
  ```
  ./start.sh clean kernel
  ./start 


## Настройка образа под задачи

### Static IP
<details><summary>В файле <code>overlay-bogdan/etc/init.d/S98eth0staticip</code> под катом ручные</summary>

```
cd /etc/init.d
mv S99usb0config S90usb0config 
mv S99_auto_reboot S90_auto_reboot
```

```nano S98eth0staticip```


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

```chmod +x S97eth0staticip ```

Другой способ убить `udhcpc` - в файле `/usr/share/udhcpc/default.script` вставить `exit` в начало
</details>       

### Часовой пояс

<details>
  <summary>Свернуто в файл <code>overlay-bogdan/etc/profile.d/msk-time.sh</code> </summary>
        
```
nano /etc/profile/msk-time.sh
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
        
Замена `DEVICES="/dev/ttyS1"` на `DEVICES="/dev/ttyS4 /dev/pps0 -G -s 115200 -n"`
        
</details>

### NTPD

<details>
 <summary>Создание симлинк gps0 и gpspps0 через <code>overlay-bogdan/lib/udev/rules.d/80-gps-to-ntp.rules</code></summary>

   ```
   KERNEL=="ttyS4", SUBSYSTEM=="tty", DRIVER=="", SYMLINK+="gps0", MODE="0666"
   KERNEL=="pps0", OWNER="root", GROUP="dialout", MODE="0660", SYMLINK+="gpspps0"
   ```

</details>

[Generic NMEA GPS Receiver](https://www.eecis.udel.edu/~mills/ntp/html/drivers/driver20.html) про настройки baudrate и различные fudge факторы <br />

<details>
 <summary>Текущие настройки <code>overlay-bogdan/etc/ntp.conf</code></summary>
        
```
# SHM Возможно ntpd вообще скомпилирован без поддержки драйвера SHM
# server 127.127.28.0 minpoll 4 maxpoll 4 prefer 
# fudge 127.127.28.0 refid NMEA

# gps0 source
# server 127.127.20.0 mode 24 prefer #9600
server 127.127.20.0 mode 88 prefer #115200
fudge 127.127.20.0 flag1 1 stratum 1

# pps0 source
server  127.127.22.0    minpoll 4 true prefer
fudge   127.127.22.0    flag3 1

# Allow only time queries, at a limited rate, sending KoD when in excess.
# Allow all local queries (IPv4, IPv6)
restrict default nomodify nopeer noquery limited kod
restrict 127.0.0.1
#restrict [::1]

```
</details>

⚠️Необходимо еще поиграть с флагами серверов и fudge, чтобы акцент делался именно на установку времени с NMEA, а уточнение с PPS<br />
⚠️Возможно GPSD и NTPD с драйвером gps0 ссорятся за порт /ttyS4 (не поддтверждено) и рекомендуется использовать драйвер SHM, который так и не заработал, потому что возможно ntpd скомпилирован без --enable-shm, решение: физически запаралеллить ttyS3 и ttyS4 и развести по разным портам GPSD и NTPD или отказаться от GPSD и получать координаты из clockstat NTPD <br />
⚠️Возможно SHM замедляет выдачу координат или времени <br />

### Использование Сhrony вместо NTP (как рекомендуют китайцы)

см. файл chrony.conf

### PTPD2
Запускать с ключами `-M -i eth0 -f /var/log/ptpd.log`, перенести 'S50ptpd2' ->  'S99ptpd2'

### Инструмент проверки NMEA GPS эмулятор
Сделан на базе [NMEA-GPS Emulator](https://github.com/luk-kop/nmea-gps-emulator.git) c такими отличиями:
при запуске с ключем -p (--port) или -b (--baudrate) сразу запускается Serial эмклятор на заданый порт и

