#!/bin/bash

# More doc about network manager dbus API at:
# https://developer.gnome.org/NetworkManager/unstable/spec.html

# In this file you can add SSIDs which will disable the lock screen
SSID_FILE="/home/denouche/.ssid-remove-lockscreen"
WIRELESS_DEVICE_NAME="wlan0"

getVariantValue ()
{
    echo "$1" | grep "variant" | cut -d '"' -f2
}

getDevices ()
{
    dbus-send --system --print-reply --type=method_call --dest='org.freedesktop.NetworkManager' '/org/freedesktop/NetworkManager' org.freedesktop.NetworkManager.GetDevices | grep "object path" | cut -d '"' -f2
}

getDeviceName ()
{
    local DEVICE="$1"
    echo "$( getVariantValue "$( dbus-send --system --print-reply --type=method_call --dest='org.freedesktop.NetworkManager' "$DEVICE" org.freedesktop.DBus.Properties.Get string:org.freedesktop.NetworkManager.Device string:Interface )" )"
}

getActiveAccessPoint ()
{
    local DEVICE="$1"
    echo "$( getVariantValue "$( dbus-send --system --print-reply --type=method_call --dest='org.freedesktop.NetworkManager' "$DEVICE" org.freedesktop.DBus.Properties.Get string:org.freedesktop.NetworkManager.Device.Wireless string:ActiveAccessPoint )" )"
}

getAccesPointSsid ()
{
    local ACCES_POINT="$1"
    echo "$( getVariantValue "$( dbus-send --system --print-reply --type=method_call --dest='org.freedesktop.NetworkManager' "$ACCES_POINT" org.freedesktop.DBus.Properties.Get string:org.freedesktop.NetworkManager.AccessPoint string:Ssid )" )"
}

containsElement ()
{
    local elem
    for elem in "${@:2}"; do [[ "$elem" == "$1" ]] && return 0; done
    return 1
}


disablePassword ()
{
    gsettings set org.gnome.desktop.screensaver lock-enabled false
}

enablePassword ()
{
    gsettings set org.gnome.desktop.screensaver lock-enabled true
}

initSsids ()
{
    mapfile -t SSID_DISABLE_LOCK_PASSWORD < $SSID_FILE
}

getWirelessDevice ()
{
    local FOUND_DEVICE
    for DEV in $( getDevices )
    do
        [ "$(getDeviceName $DEV)" = "$WIRELESS_DEVICE_NAME" ] && FOUND_DEVICE="$DEV" && break
    done
    echo "$FOUND_DEVICE"
}

main ()
{
    while read line
    do
        initSsids
        WIRELESS_DEVICE=$( getWirelessDevice )
        ACTIVE_ACCESS_POINT=$( getActiveAccessPoint "$WIRELESS_DEVICE" )
        if [ "$ACTIVE_ACCESS_POINT" = "/" ]
        then
            enablePassword
        else
            SSID=$( getAccesPointSsid $ACTIVE_ACCESS_POINT )
            if containsElement "$SSID" "${SSID_DISABLE_LOCK_PASSWORD[@]}"
            then
                disablePassword
            else 
                enablePassword
            fi
        fi
    done < <(dbus-monitor --system --profile "type='signal',interface='org.freedesktop.NetworkManager'")
}

main



