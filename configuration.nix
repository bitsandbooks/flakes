# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./user-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ]; # Enable flakes.
    substituters = [
      "http://192.168.5.50"
      "https://cache.nixos.org"
    ];
    # Optional but recommended: require signatures from the official cache
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  boot = {
    # PERSISTENCE: Roll the root dataset back to its blank snapshot on every boot
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r trunk/local/root@blank
    '';
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs = {
      devNodes = "/dev/disk/by-partuuid"; # Necessary for zpool to import on boot.
      # forceImportRoot = false; # default as of 26.11
    };
  };

  etc = {
    # PERSISTENCE: NetworkManager connections
    "NetworkManager/system-connections" = {
      source = "/persist/etc/NetworkManager/system-connections/";
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      curl
      htop
      git
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      zsh
    ];
  };

  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    firewall = {
      # Open ports in the firewall.
      allowedTCPPorts = [
        22
      ];
      allowedUDPPorts = [
        22
      ];
    };
    hostId = "0123abcd"; # Hex value; required for ZFS.
    hostName = "nixos-2605-base"; # Define your hostname.
    networkmanager.enable = true;
    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  programs = {
    zsh = {
      enable = true;
      ohMyZsh.enable = true;
    };
  };

  services = {
    # services.libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).
    openssh = {
      enable = true; # Enable the OpenSSH daemon.
      settings.PermitRootLogin = "yes";
      hostKeys = [
        # PERSISTENCE: SSH host keys
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
    pipewire = {
      # sound server
      enable = true;
      pulse.enable = true;
    };
    printing.enable = true; # Enable CUPS to print documents.
    qemuGuest.enable = true;
    # services.xserver = {
    #   enable = true;
    #   xkb = {
    #     # Configure keymap in X11
    #     layout = "us";
    #     options = "eurosign:e,caps:escape";
    #   };
    # };
  };

  systemd = {
    # PERSISTENCE: Bluetooth pairing information, ACME certificates, etc.
    tmpfiles.rules = [
      "L /var/lib/bluetooth - - - - /persist/var/lib/bluetooth"
      "L /var/lib/acme - - - - /persist/var/lib/acme"
    ];
  };

  time.timeZone = "America/Chicago";

  # Module stuff
  user-configuration = {
    enable = true;
    users.torgo = {
      uid = 9000;
      gid = 9000;
      groupName = "nihilsum";
      description = "Torgo the Caretaker";
      packages = with pkgs; [
        btop
        fastfetch
        uv
      ];
    };
    users.rob = {
      uid = 9001;
      gid = 9000;
      groupName = "nihilsum";
      description = "Rob Dumas";
      packages = with pkgs; [ 
        btop
        fastfetch
        uv
      ];
    };
  };

  zramSwap = {
    enable = true;
    # Limit the zram disk to a maximum of 75% of total system RAM
    memoryPercent = 75;
    # Cap the absolute maximum size at 6 GB (Nix evaluates this math directly into bytes)
    memoryMax = 6 * 1024 * 1024 * 1024;
  };

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05";

}
