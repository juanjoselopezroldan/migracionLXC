#!/bin/bash

estadomaq1=$(lxc-ls -f | grep debian1 | tr -s " " | cut -d " " -f 2)

if [[ estadomaq1 == 'RUNNING' ]]; then

else
  lxc-start -n debian1
  sleep 2

  ip1=$(lxc-ls --fancy | tr -s " " | cut -d " " -f 5 |  head -2 | tail -1)

fi
