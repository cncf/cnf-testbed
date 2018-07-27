#! /bin/bash

sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="isolcpus=1,2 rcu_nocbs=1,2 nohz_full=1,2"/g' /etc/default/grub
sudo update-grub2
sudo reboot
