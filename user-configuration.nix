{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.user-configuration;
in
{
  options.user-configuration = {
    enable = lib.mkEnableOption "enable user module";
    groupName = lib.mkOption {
      default = "group0";
      description = ''
        Group Description
      '';
    };
    userName = lib.mkOption {
      default = "mainuser";
      description = ''
        User Description
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      groups.${cfg.groupName}.gid = 9000;
      users.${cfg.userName} = {
        description = "Torgo the Caretaker";
        isNormalUser = true;
        group = "nihilsum";
        extraGroups = [
          "wheel" # Enable `sudo` for the user.
        ];
        shell = pkgs.zsh;
        uid = 9000;
        hashedPasswordFile = "./secrets/torgo.passwd"; # Use a hashed password for security.
        home = "/home/torgo";
        packages = with pkgs; [
          fastfetch
        ];
      };
    };
    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      users = {
        "torgo" = import ./home/torgo.nix;
      };
    };
    nixpkgs.config.allowUnfree = true;
  };
}
