{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # CRITICAL: Verify this is the correct block device for your Proxmox VM!
        # It might be /dev/vda or /dev/nvme0n1 depending on your VM settings.
        device = "/dev/sda"; 
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Carrying over the exact mount options from your hardware config
                mountOptions = [ "fmask=0022" "dmask=0022" ]; 
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "trunk";
              };
            };
          };
        };
      };
    };
    zpool = {
      trunk = {
        type = "zpool";
        rootFsOptions = {
          # Enabling LZ4 compression is highly recommended for ZFS root pools
          compression = "zstd";
          mountpoint = "none";
        };
        datasets = {
          "system/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "user/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "local/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}