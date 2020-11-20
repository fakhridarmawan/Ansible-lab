#!/bin/bash

curl https://kambing.ui.ac.id/iso/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-DVD-1908.iso --output /home/pujiriawan/CENTOS7-7.iso
mount -o loop /home/pujiriawan/CENTOS7-7.iso /mnt
cp /mnt/media.repo /etc/yum.repos.d/rhel7.repo
chmod 644 /etc/yum.repos.d/rhel7.repo

cat <<  EOF  > /etc/yum.repos.d/rhel7.repo
enabled=1
baseurl=file:///mnt/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

