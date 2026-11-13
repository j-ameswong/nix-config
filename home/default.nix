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
  # Named to sort after Ubuntu's 99-environment.conf (/etc/environment), which sets PATH outright.
  xdg.configFile."environment.d/999-path.conf".text = ''
    PATH=${config.home.homeDirectory}/.local/bin:${config.home.homeDirectory}/.opencode/bin:${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:''${PATH}
  '';

  # systemd reads environment.d only when the user manager starts, so hand the result to the
  # running one too. Services pick it up when they next restart.
  home.activation.importUserEnvironment = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    generator=/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator
    if [[ -x $generator ]] && systemctl --user show-environment >/dev/null 2>&1; then
      mapfile -t user_env < <("$generator")
      run systemctl --user set-environment "''${user_env[@]}"
    fi
  '';

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
  news.display = "silent";
}
