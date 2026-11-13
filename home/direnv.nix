{ config, ... }:
let
  home = config.home.homeDirectory;
  direnv = "${config.programs.direnv.package}/bin/direnv";
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        hide_env_diff = true;
        warn_timeout = "5m";
      };
      # T3 Code starts agents in fresh worktrees that nobody has run `direnv allow` in.
      whitelist.prefix = [
        "${home}/${config.my.projectsDir}"
        "${home}/.t3"
      ];
    };
  };

  # Agents run each command in a new non-interactive shell, where direnv's prompt hook never
  # fires. These load the project's environment into those shells instead. T3 Code's service
  # sets the variables below, so ordinary scripts are unaffected.
  xdg.configFile = {
    "agent-shell/env.bash".text = ''
      eval "$(${direnv} export bash 2>/dev/null)"
    '';
    "agent-shell/env.zsh".text = ''
      if [[ -n $AGENT_SHELL_DIRENV && ! -o interactive ]]; then
        eval "$(${direnv} export zsh 2>/dev/null)"
      fi
    '';
  };

  home.file.".t3/service.env".text = ''
    AGENT_SHELL_DIRENV=1
    BASH_ENV=${home}/.config/agent-shell/env.bash
  '';
}
