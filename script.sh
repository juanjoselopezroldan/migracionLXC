#!/bin/bash

estadomaq1=$(lxc-ls -f | grep debian1 | tr -s " " | cut -d " " -f 2)
estadomaq2=$(lxc-ls -f | grep debian2 | tr -s " " | cut -d " " -f 2)
if [[ estadomaq1 == 'RUNNING' and estadomaq2 == 'STOPPED' ]]; then
  memoria1=$(lxc-info -n debian1 | grep 'Memory use' | tr -s " " | cut -d " " -f 3)
  if [[ $memoria1 -ge '470.00' ]]; then
    ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
    iptables -t nat -D PREROUTING $ip1

    umount /mnt/debian1/var/www/html/

    lxc-start -n debian2

    ip2=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 | tail -1)
    iptables -I FORWARD -d $ip2/32 -p tcp --dport 80 -j ACCEPT
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip2:80

    mount /dev/disco/lv1 /mnt/debian2/var/www/html/


  fi
elif [[ estadomaq1 == 'STOPPED' and estadomaq2 == 'STOPPED' ]]; then
  lxc-start -n debian1
  sleep 2
  mount /dev/disco/lv1 /mnt/debian1/var/www/html/
  ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
  iptables -I FORWARD -d $ip1/32 -p tcp --dport 80 -j ACCEPT
  iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip1:80
fi
