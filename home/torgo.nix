{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "torgo";
    homeDirectory = "/home/torgo";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "26.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      (lib.hiPrio home-manager)
      oh-my-zsh

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    file = {
      ".config/home-manager/home.nix".source = ./torgo.nix;
      ".config/git/ignore".text = ''
        # Numerous always-ignore extensions #
        #####################################
        *~
        *.temp
        *.diff
        *.err
        *.orig
        *.log
        *.rej
        *.swo
        *.swp
        *.vi
        *.sass-cache
        .temp
        temp/*
        tmp/*

        # OS and/or Editor files/folders #
        ##################################
        *.esproj
        *.komodoproject
        *.sublime-project
        *.sublime-workspace
        ._*
        .cache
        .vscode
        .DS_Store
        .komodotools
        .project
        .settings
        .Spotlight-V100
        .DocumentRevisions-V100
        .tmproj
        .Trashes
        Thumbs.db
        desktop.ini
        nbproject

        # Xcode rubbish #
        #################
        *.mode1
        *.mode1v3
        *.mode2v3
        *.perspective
        *.perspectivev3
        *.pbxuser
        VersionX-revision.h
        xcuserdata/*

        # Build products #
        ##################
        *.[oa]
        *.pyc
        build/*

        # Other source repository directories #
        #######################################
        .CVS
        .hg
        .idea
        .svn
        CVS

        # Automatic backup files #
        ##########################
        *~.nib
        *.swp
        *(Autosaved).rtfd/
        Backup[ ]of[ ]*.pages/
        Backup[ ]of[ ]*.key/
        Backup[ ]of[ ]*.numbers/
        
        # SyncThing metadata #
        ######################
        .stfolder

        # Python Pip and UV environments #
        ##################################
        .venv
        venv
      '';
      ".gitconfig".text = ''
        [user]
            name = Rob Dumas
            email = robdumas@gmail.com
            signingkey = A12A2DC372239176F5149EA54853BF25C93EE1F6
        [core]
            excludesfile = /Users/rob/.local/gitignore.txt
        [difftool "sourcetree"]
            cmd = opendiff \"$LOCAL\" \"$REMOTE\"
            path =
        [mergetool "sourcetree"]
            cmd = /Applications/Sourcetree.app/Contents/Resources/opendiff-w.sh \"$LOCAL\" \"$REMOTE\" -ancestor \"$BASE\" -merge \"$MERGED\"
            trustExitCode = true
        [commit]
            template = /Users/rob/.stCommitMsg
            gpgsign = true
        [init]
            defaultBranch = trunk
        [gpg]
            program = /usr/local/MacGPG2/bin/gpg2
            format = openpgp
      '';
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. These will be explicitly sourced when using a
    # shell provided by Home Manager. If you don't want to manage your shell
    # through Home Manager then you have to manually source 'hm-session-vars.sh'
    # located at either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/torgo/etc/profile.d/hm-session-vars.sh
    #
    sessionVariables = {
      EDITOR = "vim";
    };
  };

  programs = {
    home-manager.enable = true; # Let Home Manager install and manage itself.
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -ahl --color=auto";
        lld = "ll | grep \"^d\"";
        path="echo $PATH | tr ':' '\\n'";
        update = "sudo nixos-rebuild switch";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ ];
        theme = "wezm+";
      };
    };
  };
}
