#!/bin/bash
useradd ansible
echo "trM3st4r47v85#@!" | passwd --stdin ansible
echo "trM3st4r47v85#@!" | passwd --stdin root
echo "trM3st4r47v85#@!" | passwd --stdin azure-administrator
touch /etc/sudoers.d/ansible
echo "ansible ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible
if [ "$HOSTNAME" == "manage-node0" ];
then
hostnamectl set-hostname master-node
dnf install git python3-pip sshpass bash-compl* -y
else
echo "Successfully deploy Hand-on Labs Ansible Environtment for RHCE 8 EX294"
fi

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config
systemctl restart sshd

echo "Successfully deploy Hand-on Labs Ansible Environtment for RHCE 8 EX294"