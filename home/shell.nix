{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.my.shell.enable {
  home.packages = with pkgs; [
    # The laptop's kitty sends TERM=xterm-kitty over SSH; without its terminfo zsh can't edit lines.
    kitty.terminfo
    btop
    curl
    eza
    fd
    jq
    neovim
    ripgrep
    tmux
    # npx and uvx, which MCP servers are usually launched with.
    nodejs_24
    uv
  ];

  home.sessionVariables.EDITOR = "nvim";

  programs.fzf.enable = true;
  programs.zoxide = {
    enable = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
    };
    shellAliases = {
      ll = "eza -lh";
      la = "eza -alh";
    };
    envExtra = ''
      source ${config.xdg.configHome}/agent-shell/env.zsh
    '';
    initContent = ''
      autoload -Uz vcs_info
      precmd_functions+=(vcs_info)
      zstyle ':vcs_info:git:*' formats '%b '
      setopt PROMPT_SUBST
      # The host name, so a shell on the server never passes for one on the laptop.
      PROMPT='%F{magenta}%m%f %F{blue}%~%f %F{red}''${vcs_info_msg_0_}%f$ '

      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
    '';
  };
}
