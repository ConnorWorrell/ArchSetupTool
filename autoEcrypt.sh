#!/bin/bash

echo "Encrypting home directory"
echo "Log out and log back in as root"
echo "    Copy this script out of folder"

[ "$1" == "" ] && echo "Provide user" && exit
user=$1

# Encrypt home directory
sudo modprobe ecryptfs && sudo ecryptfs-migrate-home -u $user
sudo cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak
Insert=$(cat /etc/pam.d/system-auth | grep -i -n "auth.*required.*pam_unix.so" | cut -d: -f1-1)
[ "$Insert" == "" ] && Insert=$(cat /etc/pam.d/system-auth | grep -i -n "auth.*default.*die.*pam.*faillock.so.*authfail" | cut -d: -f1-1)
eval "sudo sed -i '$Insert a auth       \[success=1 default=ignore\]  pam_succeed_if\.so service = systemd-user quiet\nauth       required                    pam_ecryptfs\.so unwrap' /etc/pam.d/system-auth"
Insert=$(expr $(cat /etc/pam.d/system-auth | grep -i -n "password.*required.*pam.*unix.so" | cut -d: -f1-1) - 1)
[ "$Insert" == "" ] && Insert=$(expr $(cat /etc/pam.d/system-auth | grep -i -n "password.*success.*default.*ignore.*pam_systemd_home.so" | cut -d: -f1-1) - 1)
eval "sudo sed -i '$Insert a password   optional                    pam_ecryptfs\.so' /etc/pam.d/system-auth"
Insert=$(cat /etc/pam.d/system-auth | grep -i -n "session.*required.*pam.*unix.so" | cut -d: -f1-1)
eval "sudo sed -i '$Insert a session    \[success=1 default=ignore\]  pam_succeed_if\.so service = systemd-user quiet\nsession    optional                    pam_ecryptfs\.so unwrap' /etc/pam.d/system-auth"

