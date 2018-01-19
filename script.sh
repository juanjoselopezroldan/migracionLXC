#!/bin/bash
echo "Iniciado"

bucle="si"

while [[ $bucle == "si" ]]; do
  estadocont1=$(lxc-ls -f | grep debian1 | tr -s " " | cut -d " " -f 2)

  if [[ $estadocont1 == "RUNNING" ]];
  then
    memoria1=$(lxc-info -n debian1 | grep 'Memory use' | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
    echo $memoria1
    if [[ $memoria1 -ge "470" ]];
    then
      echo "Deshaciendo iptables y apagando contenedor 1"
      ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
      delip=$(iptables -t nat -L --line-number | egrep $ip1 | cut -d " " -f 1)
      iptables -t nat -D PREROUTING $delip
      lxc-attach -n debian1 -- umount /dev/mapper/disco-lv1 /var/www/html
      lxc-device -n debian1 del /dev/mapper/disco-lv1
      lxc-stop -n debian1

      echo "Iniciando contenedor 2 y obteniendo ip para configuración de iptables"
      lxc-start -n debian2
      sleep 2

      ip2=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 | tail -1)
      iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip2:80
      echo "Montando volumen"
      lxc-device -n debian2 add /dev/mapper/disco-lv1
      lxc-attach -n debian2 -- mount /dev/mapper/disco-lv1 /var/www/html
      lxc-attach -n debian2 -- systemctl restart apache2

      echo "Contenedor 2 Operativo"
      bucle="no"
    fi
  else
    echo "Contenedor 1 inactivo, levantando..."
    lxc-start -n debian1
    echo "Montando volumen y obteniendo IP para regla de IPTABLES"
    sleep 2
    lxc-device -n debian1 add /dev/mapper/disco-lv1
    lxc-attach -n debian1 -- mount /dev/mapper/disco-lv1 /var/www/html
    lxc-attach -n debian1 -- systemctl restart apache2

    ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip1:80
    echo "Contenedor 1 Operativo"
  fi
  sleep 2
done

bucle="si"

while [[ $bucle == "si" ]]; do
  estadocont2=$(lxc-ls -f | grep debian2 | tr -s " " | cut -d " " -f 2)
  if [[ $estadocont2 == "RUNNING" ]];
  then
    memoria2=$(lxc-info -n debian2 | grep 'Memory use' | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
    echo $memoria2
    if [[ $memoria2 -ge '980' ]];
    then
      echo "Aumentando RAM de contenedor 2, por ram saturada"
      lxc-cgroup -n debian2 memory.limit_in_bytes 2048M
      bucle="no"
    fi
  fi
  sleep 2
done
