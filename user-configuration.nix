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
        hashedPassword = "$6$2ZPIIRNC2AW5LqLQ$GGHwcEwyuGUiyxKLcCs5pxy5CwKqEvLMmpB6zLOw4/RlLPJT2VN9b8ewZkDwl5RJn45Q5j90ZoI2HuaFMMPgP/";
        home = "/home/torgo";
        packages = with pkgs; [
          neofetch
        ];
      };
    };
    home-manager = {
      specialArgs = { inherit inputs; };
      users = {
        "torgo" = import ./home.nix;
      };
    };
    nixpkgs.config.allowUnfree = true;
  };
}
