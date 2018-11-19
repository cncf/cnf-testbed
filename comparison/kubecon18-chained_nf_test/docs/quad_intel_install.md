# Additional steps for quad intel 

Between deployment and test execute these additional configuration steps are required.


## BIOS  


1. Go to the [packet app] of your project
1. Under each of your quad intel nodes retrieve out-of-band console information
    ![oob](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/images/oob.png)
1. ssh connect to the supplied address
1. login and reboot node ```shutdown -r now```
1. Hit F2 when prompted to enter the bios.
1. When done enter ESC to save changes and reboot

![system_bios](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/images/system_bios.png)

![system_devices](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/images/system_devices.png)

![system_profile](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/images/system_profile.png)

## GRUB

coming soon

[packet]: https://www.packet.net "Packet.net"
[packet app]: https://app.packet.net "Packet portal"
[packet account setup]: https://help.packet.net/article/13-portal#display--description "packet setup"