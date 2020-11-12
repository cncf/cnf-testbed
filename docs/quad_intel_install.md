# Additional steps for quad intel 

Between deployment and test execute these additional configuration steps are required.


## BIOS  


1. Go to the [Equinix Metal Console](http://console.equinix.com/) of your project
1. Under each of your quad intel nodes retrieve out-of-band console information
    ![oob](./images/oob.png)
1. ssh connect to the supplied address
1. login and reboot node ```shutdown -r now```
1. Hit F2 when prompted to enter the bios.
1. When done enter ESC to save changes and reboot

![system_bios](./images/system_bios.png)

![system_devices](./images/system_devices.png)

![system_profile](./images/system_profile.png)

## GRUB alteration

1. Login as root to intel quad nic servers
1. Create backup grub file

    ```cp /etc/default/grub /etc/default/grub.bak```
1. edit /etc/default/grub
1. replace GRUB_CMDLINE_LINUX with line below
    ```
    GRUB_CMDLINE_LINUX="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1 numa_balancing=disable hugepagesz=2M hugepages=8096 isolcpu=2-27,30-55 rcu_nocbs=2-27,30-55 nohz_full=2-27,30-55 nmi_watchdog=0 audit=0 nosoftlockup processor.max_cstate=1 intel_idle.max_cstate=1 hpet=disable tsc=reliable mce=off numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt"
    ```

1. update with changed line

    ```update-grub2```
1. reboot

    ```shutdown -r now```

