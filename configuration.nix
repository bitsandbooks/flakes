# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.devNodes = "/dev/disk/by-partuuid"; # Necessary for zpool to import on boot.
  };

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      curl
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      zsh
    ];
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
    };
    # pipewire = {
    #   # sound server
    #   enable = true;
    #   pulse.enable = true;
    # };
    # printing.enable = true; # Enable CUPS to print documents.
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

  # Module stuff
  user-configuration.enable = true;
  user-configuration.groupName = "nihilsum";
  user-configuration.userName = "torgo";

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05";

}
