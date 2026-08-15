{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.user-configuration;

  userSubmodule = { name, ... }: {
    options = {
      uid = lib.mkOption {
        type = lib.types.int;
        description = ''
          Explicit numeric UID. Required (no default/auto-assignment) because
          this maps directly to file ownership on persistent ZFS storage that
          survives the root-dataset rollback-on-boot.
        '';
      };

      gid = lib.mkOption {
        type = lib.types.int;
        description = ''
          Explicit numeric GID for this user's primary group. Required for the
          same stability reasons as `uid`. Only actually used to create the
          group when `createGroup = true`.
        '';
      };

      groupName = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = ''
          Name of this user's primary group. Defaults to the username; set to
          an existing group name (and `createGroup = false`) to share a group
          across multiple users.
        '';
      };

      createGroup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether this user's entry defines the `groupName` group (with this
          user's `gid`). Set to `false` on every user after the first one that
          shares a `groupName`, to avoid conflicting/duplicate group
          definitions.
        '';
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "GECOS description for the user.";
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "wheel" ];
        description = "Supplementary groups for the user.";
      };

      shell = lib.mkOption {
        type = lib.types.package;
        default = pkgs.zsh;
        description = "Login shell package.";
      };

      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/${name}";
        description = "Home directory path.";
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = "/etc/nixos/secrets/${name}.passwd";
        description = "Path to the file containing the hashed password.";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Extra user-scoped packages.";
      };

      homeManagerModule = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./home + "/${name}.nix";
        description = ''
          Path to this user's home-manager module, imported into
          `home-manager.users.<name>`. Set to `null` to skip home-manager for
          this user.
        '';
      };
    };
  };
in
{
  options.user-configuration = {
    enable = lib.mkEnableOption "enable user module";

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule userSubmodule);
      default = { };
      description = ''
        Set of system users to create, keyed by username. See
        `userSubmodule` options for per-user configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      groups = lib.mapAttrs'
        (name: u: lib.nameValuePair u.groupName { gid = u.gid; })
        (lib.filterAttrs (name: u: u.createGroup) cfg.users);

      users = lib.mapAttrs
        (name: u: {
          description = u.description;
          isNormalUser = true;
          group = u.groupName;
          extraGroups = u.extraGroups;
          shell = u.shell;
          uid = u.uid;
          hashedPasswordFile = u.hashedPasswordFile;
          home = u.home;
          packages = u.packages;
        })
        cfg.users;
    };

    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      users = lib.mapAttrs
        (name: u: import u.homeManagerModule)
        (lib.filterAttrs (name: u: u.homeManagerModule != null) cfg.users);
    };

    nixpkgs.config.allowUnfree = true;
  };
}
