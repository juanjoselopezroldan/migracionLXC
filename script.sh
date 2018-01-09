#!/bin/bash
echo "Iniciando"
estadocont1=$(lxc-ls -f | grep debian1 | tr -s " " | cut -d " " -f 2)
estadocont2=$(lxc-ls -f | grep debian2 | tr -s " " | cut -d " " -f 2)

if [[ estadocont1 == "RUNNING" ]] && [[ estadocont2 == "STOPPED" ]]; then
  memoria1=$(lxc-info -n debian1 | grep 'Memory use' | tr -s " " | cut -d " " -f 3)
  if [[ $memoria1 -ge '470.00' ]]; then
    ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
    iptables -t nat -D PREROUTING $ip1

    umount /mnt/debian1/var/www/html/
    lxc-stop -n debian1
    lxc-start -n debian2

    ip2=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 | tail -1)
    iptables -I FORWARD -d $ip2/32 -p tcp --dport 80 -j ACCEPT
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip2:80

    mount /dev/disco/lv1 /mnt/debian2/var/www/html/

  fi
elif [[ estadocont1 == "STOPPED" ]] && [[ estadocont2 == "STOPPED" ]]; then
  echo "Contenedor 1 inactivo, levantando..."
  lxc-start -n debian1
  echo "Montando volumen y obteniendo IP para regla de IPTABLES"
  sleep 2
  mount /dev/disco/lv1 /mnt/debian1/var/www/html/
  ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
  iptables -I FORWARD -d $ip1/32 -p tcp --dport 80 -j ACCEPT
  iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip1:80
  echo "Contenedor 1 Operativo"
fi

#if [[ estadocont2 == "RUNNING" ]]; then
#  memoria2=$(lxc-info -n debian2 | grep 'Memory use' | tr -s " " | cut -d " " -f 3)
#  if [[ $memoria2 -ge '980.00' ]]; then
    #statements
#  fi
#fi
