{ pkgs, ... }:
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

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
  news.display = "silent";
}
