#!/bin/bash
if [ "$HOSTNAME" == "master-node" ];
then
pip3 install ansible==2.8 --user
else
echo "Berhasil install ansible 2.8 di master node untuk keperluan Hands on Labs RHCE 8 EX294"
fi
touch /home/azure-administrator/.vimrc
cat <<'BARIS' > /home/azure-administrator/.vimrc
autocmd FileType yaml setlocal ai sw=2 ts=2 et cuc cul
autocmd FileType yml setlocal ai sw=2 ts=2 et cuc cul
set number
set ruler
colorscheme desert
syntax on
BARIS

cat <<'COMMAND' >> /home/azure-administrator/.bashrc
alias ap='ansible-playbook'
alias aps='ansible-playbook --syntax-check'
alias a='ansible'
alias ag='ansible-galaxy'
alias av='ansible-vault'
docex() {
ansible-doc $1 | grep EXAMPLES -A 100 | less
}

docls() {
ansible-doc -s $1
}
COMMAND
source /home/azure-administrator/.bashrc

touch /home/azure-administrator/auto-shutdown.sh
cat <<'AUTO-SHUTDOWN' > /home/azure-administrator/auto-shutdown.sh
#!/bin/bash
#
# This is scheduled in CRON using ROOT, it runs every 5 minutes 
# and uses who -a to determine user activity. Once the idle time is
# more than the threshold value it shuts the system down.
#
echo "Start of sidle.shl"

threshold=15
log=/home/azure-administrator/sidle.log
userid=azure-administrator
inactive=`who -a | grep $userid | cut -c 45-46 | sed 's/ //g'`

if [ "$inactive" != "" ]; then

echo "Idle time is: " $inactive

if [ "$inactive" -gt "$threshold" ]; then
echo "Threshold met so issuing shutdown command"
/sbin/shutdown -h now
else
echo "Bellow threshold"
fi
else
echo "Idle time is: 0"
fi 
echo "Ending"
AUTO-SHUTDOWN
chmod +x /home/azure-administrator/auto-shutdown.sh






