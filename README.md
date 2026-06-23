# Installing NixOS

Start here: on a libvirt host with a VM booted from the NixOS ISO. The VM in this tutorial has one disk attached for the UEFI system partition and the ZFS pool that NixOS will use. It has 8 GB of memory, which our configuration files will augment with a 6 GB zram swap device.

1. Set the password for the installer's default user "nixos" with `passwd`.
2. Get the IP address of the virtual machine with `ip addr`. Look for the connected network device. for example:

        1: enp7s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
            link/ether 52:54:00:26:55:c3 brd ff:ff:ff:ff:ff:ff
            inet 192.168.122.212/24 brd 192.168.122.255 scope global dynamic noprefixroute enp7s0
               valid_lft 2662sec preferred_lft 2662sec

3. Now open a terminal on your machine (or other machine on the same network) and connect to the VM with `ssh -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null nixos@192.168.122.212`.

You are now connected to the VM and ready for install.

## Flake or Manual Installation?

This repo contains a simple flake for a `testvm` virtual machine, or you can partition the system manually. Choose one, then move on to the **Ready for Install!** section.

### Using Flakes and Disko

1. Clone the repo to the VM with `git clone https://github.com/bitsandbooks/flakes.git`.
2. Partitionthe disk using disko with `sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake ./flakes#testvm`.
3. Install NixOS on the newly-partitioned disk with `sudo nixos-install --flake ./flakes#testvm`. The installer will run for a while.

### Using the Manual Method

1. Check block devices and free memory with `lsblk` and `free -h`. (This tutorial assumes your disk is `sda`, but it may be something different, such as `vda` or `hda`.)

        $ lsblk
        NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
        loop0   7:0    0 787.3M  1 loop
        sr0    11:0    1   820M  0  rom /iso
        sda   253:0    0    64G  0 disk
        
        $ free -h
               total   used   free  shared  buff/cache  available
        Mem:   7.8Gi  140Mi  7.3Gi    29Mi       273Mi      7.4Gi
        Swap:     0B     0B     0B

2. Partition the disk using `sudo gdisk /dev/sda` into a 2-gigabyte UEFI firmware partition and a ZFS partition for the rest: 
    1. Print the current (empty) partition table with `p`.
    2. Clear the partition table and create a new one (deleting any existing partitions in the process) with `o`.
    3. Create the UEFI firmware partition (`/dev/sda1`) with `n`, followed by: 
        1. `Enter ↵` to accept the default *next partition number* (1).
        2. `Enter ↵` to accept the default *first sector* for the partition.
        3. `+2G` to make the disk 2 GB in size.
        4. `ef00` to label the partition as a UEFI firmware partition (or type `L` to see a list of partition types that gdisk knows about, or to find the code for one you can't remember.)
    4. Create the "rest of the disk" ZFS pool partition (`/dev/sda2`) with `n`, followed by: 
        1. `Enter ↵` to accept the default *next partition number* (2).
        2. `Enter ↵` to accept the default *first sector* for the partition.
        3. `Enter ↵` to allow the partition to use all remaining space on the disk.
        4. `a504` to label the partition as a "FreeBSD ZFS" partition.
    5. Check the new partition table with `p`. You should see the two partitions we just created.
    6. Write the new partition table to disk and exit with `w`.
3. Format and label the firmware partition with `mkfs.vfat -F 32 -n FIRMWARE /dev/sda1`
4. Set up the ZFS pool:
    1. Check that there are no pools available with `zpool status`.
    2. List partitions on `sda` by their unique identifier with `l /dev/disk/by-partuuid/`. Make note of the one that is symlinked to `/dev/sda2`; here, we will use the UUID `a88e1008-5456-46f0-8513-0a6d43f43ce4`.
    3. Create the options needed to build the zpool:
        1. Create an environment variable pointing to our *vdev* (in this case, the second partition on the disk) with:
        
                VDEV=/dev/disk/by-partuuid/a88e1008-5456-46f0-8513-0a6d43f43ce4
                
            *Use this unique identifier instead of "sda2"*, as that short device name can change based on the order of devices recognized during boot-up.
        2. Create an environment variable for the zpool's name, with:

                POOLNAME=trunk` (or whatever you want to name your zpool).
            
        3. Set options for the zpool with:
        
                POOLOPTIONS="-o ashift=12"
            
            Note the *lowercase* "-o", which represents *options set on the pool and its devices*.
            
            The `ashift=12` property tells ZFS to make sure to use larger 4 KB sectors on the disk instead of the older 512 B sectors.
            
            You can also add:
            
            - The `autotrim=on` property is great for pools on solid-state disks, as it allows ZFS to efficiently trim old blocks on the disk. 
            - The `autoexpand=on` property for multi-disk pools (such as many common "striped" RAID arrays) so that when the disks get full, you can replace the disks one at a time with larger disks (letting the pool heal in between each) and when the last one is done, the pool will automatically increase in capacity.
        4. Set options for the default dataset with:
        
                DATASETOPTIONS="-O compression=zstd \
                                -O canmount=off \
                                -O mountpoint=legacy \
                                -O relatime=on \
                                -O dnodesize=auto \
                                -O normalization=formD \
                                -O xattr=sa \
                                -O acltype=posixacl"
            
            (Note the *uppercase* "-O", which represents *options set on the first dataset created*, named for the pool; in this case, `trunk`. All descendent datasets inherit these settings from the default unless overriden.)

            The options mean:

            - `compression=zstd`: use the [zstd](https://zstandard.org/) compression algorithm
            - `canmount=off`: for NixOS installs, because the installer will set up mounts
            - `mountpoint=legacy`: for NixOS installs, because the installer will set up mounts
            - `relatime=on`: turn on "relative access time" which cuts down on pointless disk I/O ops
            - `dnodesize=auto`: set to `auto if the dataset uses the xattr=sa property
            - `normalization=formD`: enforce UTF-8 filenames
            - `xattr=sa`: store extended attributes directly in the inodes
            - `acltype=posixacl`: use POSIX-compatible access control lists

        5. Create the ZFS pool using the options chosen with:
        
                zpool create $POOLOPTIONS $DATASETOPTIONS $POOLNAME $VDEV
        
        6. Check the zpool's status with `zpool status`.  You should see just one, called `trunk`, like so:

                  pool: trunk
                 state: ONLINE
                config:
                zpool status
  	            NAME                                      STATE     READ WRITE CKSUM
	              trunk                                   ONLINE       0     0     0
	                a88e1008-5456-46f0-8513-0a6d43f43ce4  ONLINE       0     0     0
                
                errors: No known data errors

        7. Check the default dataset (filesystem) in the zpool with `zfs list`.
        
                NAME   USED  AVAIL  REFER  MOUNTPOINT
                trunk  408K  62.0G    96K  legacy

        8. Create the ZFS datasets our NixOS system will need:

                zfs create -p $POOLNAME/system/root $POOLNAME/local/nix $POOLNAME/local/var $POOLNAME/user/home
            
            The "nix" dataset doesn't need to know roughly how long ago a file in it was last accessed, so override the `atime` and `relatime` properties by using `zfs set`:

                zfs set atime=off $POOLNAME/local/nix
                zfs set relatime=off $POOLNAME/local/nix
            
            ZFS makes taking snapshots of datasets very easy, so since we haven't yet installed, let's take snapshots of our "root" and "nix" datasets while they're still empty:

                zfs snapshot $POOLNAME/local/nix@blank
                zfs snapshot $POOLNAME/system/root@blank

        9. List the ZFS datasets and snapshots again with: 

                zfs list
                zfs list -t snapshot
        
        10. Mount the root dataset at `/mnt`, create folders inside the root into which we can mount our other respective datasets, then mount them:
        
                mount -t zfs $POOLNAME/system/root /mnt
                mkdir /mnt/boot /mnt/home /mnt/nix /mnt/var
                mount -t vfat /dev/disk/by-label/FIRMWARE /mnt/boot
                mount -t zfs $POOLNAME/user/home /mnt/home
                mount -t zfs $POOLNAME/local/nix /mnt/nix
                mount -t zfs $POOLNAME/local/var /mnt/var
        
        11. Go to the nixos-config folder with `cd /mnt/etc/nixos`.
        12. Clone the flake to the new install with:

                git clone https://github.com/bitsandbooks/flakes.git .

        13. Generate your hardware config

                nixos-generate-config --root /mnt
        
        14. Create a password hash with...
        
                `openssl passwd -6`
            
            ...and copy the hash into a file called `/mnt/etc/nixos/secrets/torgo.passwd`.

## Ready for Intall!

Install Nixos with: `nixos-install --flake /etc/nixos#testvm`.

When the installer ends, you'll be back where you started: a terminal prompt. You can now reboot or shutdown, and remove the ISO from the virtual ROM drive. Once the machine boots up again, you should be able to log in with `torgo` and the user's password.