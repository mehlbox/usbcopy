#!/bin/bash

callRsync () {
  if touch "$i/readwrtecheck_AllUSB.info"
  then
    rm "$i/readwrtecheck_AllUSB.info" 2>/dev/null
    rsync -r --delete --size-only "/usbcopy-files/" "$i/Missionskonferenz 2019" 2>/dev/null
    if [ $? -ne 0 ]
    then
      echo "Fehler beim syncronisieren mit $i !!!!"
    else
      echo "Syncronisation mit $i abgeschlossen."
    fi
  else
    echo "Schreiben auf $i fehlgeschlagen."
  fi
}

echo "Initialisieren..."
umount -l /media/usbcopy/* 2>/dev/null

echo "syncronisiere mit Netzwerk..."
rsync -rv --size-only --delete --exclude=@eaDir --rsync-path=/opt/bin/rsync nas:"/volume1/Aufnahme-stereo/015\ Missionskonferenz/Missionskonferenz\ 2019/" "/usbcopy-files/"

if [ $? -ne 0 ]
then
  echo "Fehler beim syncronisieren mit Netzwerk !!!!"
  echo "ABBRUCH !!!"
  exit 1
fi

#list all connected drives
enter=true
while $enter
do
  clear
  unset dev
    portcount=0
    echo "USB-HUB $deviceFile:"
    echo "Nr.| Status | Device"
    echo "---+--------+----------------------"
    for devicename in /dev/disk/by-path/pci-0000:00:1?.0-usb-0:*-scsi-0:0:0:0
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
  echo "Syncronisation starten? (j/n)"
  echo "STRG + C zum beenden"
  read -n 1 -t 1 input
  if [ "$input" = "j" ]; then
    echo
    echo "Syncronisation wird gestartet."
    break
  fi
done

echo "Es wurden ${#dev[@]} Geräte erkannt"
echo "Verbinde Geräte..."

#for each device in created list
for i in ${dev[@]}
do

  j=$((j+1))
  #make empty folder for mountpoint
  if [ ! -d /media/usbcopy/usb$j ]
  then
    mkdir /media/usbcopy/usb$j
  fi

  #mount
  if mount $i"-part1" /media/usbcopy/usb$j &>/dev/null
  then
    if grep -qs "/media/usbcopy/usb$j" /proc/mounts
    then
      echo "Device:$(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 ) als usb$j eingebunden!"
      mountPath+=("/media/usbcopy/usb$j")
    else
      echo "Device:$(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 ) Fehler beim einbinden. Wurde fehlerhaft eingebunden. Wird nicht syncronisiert!"
    fi
  else
    echo "Device:$(echo $i | cut -c 42- | cut -d - -f1 | cut -d : -f1 ) Fehler beim einbinden. Konnte nicht eingebunden werden. Wird nicht syncronisiert!"
  fi
done

echo "Kopiere Dateien..."
for i in ${mountPath[@]}
do
  if grep -qs $i /proc/mounts
  then
    callRsync &
  else
    echo "Fehler: Gerät nicht eingebunden."
  fi
done
wait

echo "Auswerfen von Geräte..."
df -h $i | head -n1
for i in ${mountPath[@]}
do
  if grep -qs $i /proc/mounts
  then
    df -h $i | sed 1d
    umount -l $i &
  else
    echo "Fehler beim auswerfen von Gerät $i"
  fi
done
wait


echo
#umount and rm used folder
umount -l /media/usbcopy/* 2>/dev/null
rmdir /media/usbcopy/* 2>/dev/null

echo "FERTIG! Es wurden ${#mountPath[@]} USB-Sticks syncronisiert"
