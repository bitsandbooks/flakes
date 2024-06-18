# Installing NixOS

Start here: on a libvirt host with a VM booted from the NixOS ISO. The VM in this tutorial has two disks attached: a 50 GB disk for the UEFI system partition and the ZFS pool that NixOS will use, and a 16 GB second disk for swap.

1. Set password for install user nixos

    passwd

2. Get IP address

    ip addr
    1: enp7s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 52:54:00:26:55:c3 brd ff:ff:ff:ff:ff:ff
        inet 192.168.122.212/24 brd 192.168.110.255 scope global dynamic noprefixroute enp7s0
           valid_lft 2662sec preferred_lft 2662sec

## Now go to another machine on the same network and SSH in

    ssh -o PreferredAuthentications=password nixos@192.168.122.212

You're now connected to the running nixos VM.

## Become the superuser

    sudo -i

## Check block devices and free memory

This tutorial assumes your two disks are `vda` and `vdb`, but they may be something different, like `sda` or `hda`.

    lsblk
    NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    loop0   7:0    0 787.3M  1 loop
    sr0    11:0    1   820M  0  rom /iso
    vda   253:0    0    50G  0 disk
    vda   253:16   0    16G  0 disk
    
    free -h
           total   used   free  shared  buff/cache  available
    Mem:   7.8Gi  140Mi  7.3Gi    29Mi       273Mi      7.4Gi
    Swap:     0B     0B     0B
## Create a single swap partition on vdb

    gdisk /dev/vdb
    > ?
    > o (y)
    > n (Enter,Enter,Enter,L,swap,8200)
    > w (y)
    mkswap /dev/vdb1
    swapon /dev/vdb1

## We should now have 16GB of swap

    free -h

## Partition vda

    gdisk /dev/vda
    > o (y)
    > n (Enter,Enter,+1G,L,efi,ef00)
    > n (Enter,Enter,Enter,L,zfs,a504)
    > w (y)

## Format and label EFI partition

    mkfs.vfat /dev/vda1
    fatlabel /dev/vda1 FIRMWARE

# Set up ZFS pool

## Show no zpools

    zpool status
    no pools available

## list partitions on vda by partition UUID

    l /dev/disk/by-partuuid/

## copy uuid that points to vda2; this is the ZFS pool vdev

    VDEV=/dev/disk/by-partuuid/a88e1008-5456-46f0-8513-0a6d43f43ce4
    POOLNAME=zp0
    POOLOPTIONS="-o ashift=12 -o autoexpand=on -o autotrim=on"
    DATASETOPTIONS="-O compression=zstd -O canmount=off -O mountpoint=legacy -O atime=off -O relatime=on -O dnodesize=auto -O normalization=formD -O xattr=sa -O acltype=posixacl"
    zpool create $POOLOPTIONS $DATASETOPTIONS $POOLNAME $VDEV
    zpool status
      pool: zp0
     state: ONLINE
    config:
    zpool status
  	NAME                                    STATE     READ WRITE CKSUM
	  zp0                                     ONLINE       0     0     0
	    a88e1008-5456-46f0-8513-0a6d43f43ce4  ONLINE       0     0     0
    
    errors: No known data errors

## List default ZFS dataset

    zfs list
    NAME    USED  AVAIL  REFER  MOUNTPOINT
    zp0     408K  47.0G    96K  legacy

## create ZFS datasets
    zfs create -p "$POOLNAME/user/home"
    zfs create -p "$POOLNAME/local/nix"
    zfs set relatime=off "$POOLNAME/local/nix"
    zfs snapshot "$POOLNAME/local/nix@blank"
    zfs create -p "$POOLNAME/system/root"
    zfs snapshot "$POOLNAME/system/root@blank"

## list ZFS datasets

    zfs list
    zfs list -t snapshot

## Mount datasets for install

    mount -t zfs "$POOLNAME/system/root" /mnt
    mkdir /mnt/boot /mnt/home /mnt/nix
    mount -t vfat /dev/vda1 /mnt/boot
    mount -t zfs "$POOLNAME/user/home" /mnt/home
    mount -t zfs "$POOLNAME/local/nix" /mnt/nix

## Generate config

    nixos-generate-config --root /mnt
