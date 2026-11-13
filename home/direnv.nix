{ config, lib, ... }:
let
  home = config.home.homeDirectory;
  direnv = "${config.programs.direnv.package}/bin/direnv";
  # The service passes these to every agent shell; see the snippets below.
  serviceEnv = {
    AGENT_SHELL_DIRENV = "1";
    BASH_ENV = "${home}/.config/agent-shell/env.bash";
  };
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
    # direnv evaluates .envrc in bash, which would read BASH_ENV and recurse without the guard.
    "agent-shell/env.bash".text = ''
      if [[ -z ''${AGENT_SHELL_DIRENV_LOADING-} ]]; then
        export AGENT_SHELL_DIRENV_LOADING=1
        eval "$(${direnv} export bash 2>/dev/null)"
        unset AGENT_SHELL_DIRENV_LOADING
      fi
    '';
    "agent-shell/env.zsh".text = ''
      if [[ -n $AGENT_SHELL_DIRENV && ! -o interactive ]]; then
        eval "$(${direnv} export zsh 2>/dev/null)"
      fi
    '';
  };

  # T3 Code writes its own settings into service.env, so it can't be a store symlink. Keep our
  # lines in it instead; T3 Code reads them on its next restart (`t3 service restart`).
  home.activation.t3ServiceEnv = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    env_file=${home}/.t3/service.env
    wanted=$(mktemp)
    { grep -vE '^(${lib.concatStringsSep "|" (lib.attrNames serviceEnv)})=' "$env_file" 2>/dev/null || true
      printf '%s\n' ${
        lib.escapeShellArgs (lib.mapAttrsToList (name: value: "${name}=${value}") serviceEnv)
      }
    } > "$wanted"
    if ! cmp -s "$wanted" "$env_file"; then
      run mkdir -p "$(dirname "$env_file")"
      run install -m 600 "$wanted" "$env_file"
    fi
    rm -f "$wanted"
  '';
}
