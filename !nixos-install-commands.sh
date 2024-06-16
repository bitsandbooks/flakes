# Start here: with a VM booted from the NixOS ISO. This VM has two disks attached.

# Set passwd
$ passwd

# Get IP address
$ ip --color=auto addr

# Now go to another machine on the same network and SSH in
$ ssh -o PreferredAuthentications=password -J libvirthost nixos@192.168.122.212

# You're now connected to the running nixos VM. In order to install NixOS, become the superuser
$ sudo -i

# Check block devices and free memory. This document assumes your two disks are `vda` and `vdb`, 
# but they may be something different, like `sda` or `hda`.
$ lsblk
NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0   7:0    0 787.3M  1 loop
sr0    11:0    1   820M  0  rom /iso
vda   253:0    0    50G  0 disk
vda   253:16   0    16G  0 disk
$ free -h
       total   used   free  shared  buff/cache  available
Mem:   7.8Gi  140Mi  7.3Gi    29Mi       273Mi      7.4Gi
Swap:     0B     0B     0B
# Create a single swap partition on vdb
$ gdisk /dev/vdb
> ?
> o (y)
> n (Enter,Enter,Enter,L,swap,8200)
> w (y)
$ mkswap /dev/vdb1
$ swapon /dev/vdb1
# We should now have 16GB of swap
$ free -h

# Partition vda
$ gdisk /dev/vda
> o (y)
> n (Enter,Enter,+1G,L,efi,ef00)
> n (Enter,Enter,Enter,L,zfs,a504)
> w (y)

# Format and label EFI partition
$ mkfs.vfat /dev/vda1
$ fatlabel /dev/vda1 FIRMWARE

# Set up ZFS pool

# Show no zpools
$ zpool status
no pools available
# list partitions on vda by partition UUID
$ l /dev/disk/by-partuuid/
# copy uuid that points to vda2; this is the ZFS pool vdev
$ VDEV="/dev/disk/by-partuuid/a88e1008-5456-46f0-8513-0a6d43f43ce4"
$ POOLNAME=trunk
$ POOLOPTIONS="-o ashift=12 -o autoexpand=on -o autotrim=on"
$ DATASETOPTIONS="-O compression=zstd -O canmount=off -O mountpoint=legacy -O atime=off -O relatime=on -O dnodesize=auto -O normalization=formD -O xattr=sa -O acltype=posixacl"
$ zpool create $POOLOPTIONS $DATASETOPTIONS $POOLNAME $VDEV
$ zpool status
  pool: trunk
 state: ONLINE
config:

	NAME                                    STATE     READ WRITE CKSUM
	trunk                                   ONLINE       0     0     0
	  a88e1008-5456-46f0-8513-0a6d43f43ce4  ONLINE       0     0     0

errors: No known data errors
# List ZFS datasets
$ zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
trunk   408K  47.0G    96K  legacy
# create ZFS datasets
$ zfs create -p "$POOLNAME/user/home"
$ zfs create -p "$POOLNAME/local/nix"
$ zfs set relatime=off "$POOLNAME/local/nix"
$ zfs snapshot "$POOLNAME/local/nix@blank"
$ zfs create -p "$POOLNAME/system/root"
$ zfs snapshot "$POOLNAME/system/root@blank"
# list ZFS datasets
$ zfs list
$ zfs list -t snapshot

# Mount datasets for install
$ mount -t zfs "$POOLNAME/system/root" /mnt
$ mkdir /mnt/boot /mnt/home /mnt/nix
$ mount -t vfat /dev/vda1 /mnt/boot
$ mount -t zfs "$POOLNAME/user/home" /mnt/home
$ mount -t zfs "$POOLNAME/local/nix" /mnt/nix

# Generate config
$ nixos-generate-config --root /mnt