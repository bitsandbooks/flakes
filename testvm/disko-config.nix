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
              size = "2G";
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
        # Pool options (-o)
        options = {
          ashift = "12";
          autoexpand = "on";
          autotrim = "on";
        };
        # Default root dataset properties (-O)
        rootFsOptions = {
          compression = "zstd";
          canmount = "off";
          mountpoint = "legacy";
          atime = "off";
          relatime = "on";
          dnodesize = "auto";
          normalization = "formD";
          xattr = "sa";
          acltype = "posixacl";
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = "zfs snapshot trunk/local/root@blank";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            properties = {
              relatime = "off";
            };
            postCreateHook = "zfs snapshot trunk/local/nix@blank";
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}