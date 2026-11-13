{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./options.nix
    ./agents.nix
    ./direnv.nix
    ./git.nix
    ./shell.nix
  ];

  home = {
    username = "contessa";
    homeDirectory = "/home/contessa";
    stateVersion = "26.05";

    packages = [ pkgs.devenv ];

    # Where the agent CLIs and t3 install themselves.
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.opencode/bin"
    ];
  };

  # User services, T3 Code and the agents it starts among them, get their PATH from the systemd
  # user manager rather than a shell.
  systemd.user.sessionVariables.PATH = lib.concatStringsSep ":" [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.opencode/bin"
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
    "\${PATH}"
  ];

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
  news.display = "silent";
}
