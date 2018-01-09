#!/bin/bash

estadomaq1=$(lxc-ls -f | grep debian1 | tr -s " " | cut -d " " -f 2)

if [[ estadomaq1 == 'RUNNING' ]]; then

else
  
fi
