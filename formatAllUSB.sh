#!/bin/bash
formatDevice () {
    echo "Erstelle neue Partition auf USB-Gerät $(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 )..."
    cleanDisc &>/dev/null
    echo "Formatiere USB-Gerät $(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 )..."
    if mkfs.vfat -F 32 $(realpath $i)1 &>/dev/null
    then
      echo "... USB-Gerät $(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 ) abgeschlossen!"
      return 0
    else
      echo "Fehler beim formatieren von USB-Gerät $(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 )"
    return 1
    fi
}

cleanDisc() {
(
# Delete up to 5 partitions
echo d
echo
echo d
echo
echo d
echo
echo d
echo
echo d
echo

echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo   # Partition number (Accept default)
echo   # First sector (Accept default)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | fdisk $(realpath $i)
}

dev=($(ls -1 /dev/sd?))
echo "Initialisieren..."
for i in ${dev[@]}
do
  #skip /dev/sda1
  if [ $i == "/dev/sda" ]
  then
    continue
  fi

  umount -l $i"1" 2>/dev/null
done

#list all connected drives
enter=true
while $enter
do
  clear
  unset dev
    portcount=0
    echo
    echo "+-----------------------------------------------+"
    echo "|                                               |"
    echo "|  #####   ####   ####   #    #    ##    #####  |"
    echo "|  #      #    #  #   #  ##  ##   #  #     #    |"
    echo "|  ###    #    #  ####   # ## #  ######    #    |"
    echo "|  #      #    #  #   #  #    #  #    #    #    |"
    echo "|  #       ####   #   #  #    #  #    #    #    |"
    echo "|                                               |"
    echo "+-----------------------------------------------+"
    echo
    echo "Nr.| Status | Device"
    echo "---+--------+----------------------"
    for devicename in /dev/disk/by-path/pci-0000:00:14.0-usb-0:*-scsi-0:0:0:0
    do
      if [ -b "$devicename" ]
      then
        if [ -b "$devicename""-part1" ]
        then
          status="  OK  "
          dev+=("$devicename")
        else
          status="noPart"
        fi
        echo "$((++portcount)): | $status | $(echo $devicename | cut -c 42- | cut -d - -f1 | cut -d : -f1 ) "
      fi
    done
    echo
  echo "Es wurden ${#dev[@]} Geräte erkannt"
  echo "Formatierung starten? (j/n)"
  echo "STRG + C zum beenden"
  read -n 1 -t 1 input
  if [ "$input" = "j" ]; then
    echo
    echo "Formatierung wird gestartet."
    break
  fi
done

echo "Es wurden ${#dev[@]} Geräte erkannt"
echo "Verbinde Geräte..."

#for each device in created list
for i in ${dev[@]}
do
  formatDevice &
done
wait

echo "FERTIG! Es wurden ${#dev[@]} USB-Geräte formatiert"
