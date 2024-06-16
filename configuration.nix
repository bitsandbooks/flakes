# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/Chicago"; # Set your time zone.

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
    hostName = "nixos-2405-base"; # Define your hostname.
    networkmanager.enable = true;
    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  boot = {
    supportedFilesystems = [ "zfs" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    zfs.devNodes = "/dev/disk/by-partuuid";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    groups.nihilsum.gid = 9000;
    users.torgo = {
      description = "Torgo the Caretaker";
      isNormalUser = true;
      group = "nihilsum";
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
      ];
      shell = pkgs.zsh;
      uid = 9000;
      hashedPassword = "$6$2ZPIIRNC2AW5LqLQ$GGHwcEwyuGUiyxKLcCs5pxy5CwKqEvLMmpB6zLOw4/RlLPJT2VN9b8ewZkDwl5RJn45Q5j90ZoI2HuaFMMPgP/";
      home = "/home/torgo";
      packages = with pkgs; [
        neofetch
      ];
    };
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
    zsh.enable = true;
  };

  services = {
    # services.libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).
    openssh.enable = true; # Enable the OpenSSH daemon.
    pipewire = {
      # sound server
      enable = true;
      pulse.enable = true;
    };
    # printing.enable = true; # Enable CUPS to print documents.
    # services.xserver = {
    #   enable = true;
    #   xkb = {
    #     # Configure keymap in X11
    #     layout = "us";
    #     options = "eurosign:e,caps:escape";
    #   };
    # };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
