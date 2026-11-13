{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The agent CLIs and t3 release faster than nixpkgs follows, and each one updates itself
  # in $HOME, so Nix only makes sure they're present.
  preamble = ''
    export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
    export CODEX_NON_INTERACTIVE=1
  '';

  agents-install = pkgs.writeShellApplication {
    name = "agents-install";
    runtimeInputs = [ pkgs.curl ];
    text = preamble + ''
      missing() { ! command -v "$1" >/dev/null; }

      if missing claude; then curl -fsSL https://claude.ai/install.sh | bash; echo "installed: claude"; fi
      if missing codex; then curl -fsSL https://chatgpt.com/codex/install.sh | sh; echo "installed: codex"; fi
      if missing opencode; then curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; echo "installed: opencode"; fi
      if missing t3; then curl -fsSL https://t3.codes/install.sh | sh; echo "installed: t3"; fi

      if ! systemctl --user cat t3code.service >/dev/null 2>&1; then
        t3 service install
        echo "installed: t3code.service"
      fi
    '';
  };

  agents-update = pkgs.writeShellApplication {
    name = "agents-update";
    runtimeInputs = [ pkgs.curl ];
    text = preamble + ''
      failed=0
      claude update || failed=1
      curl -fsSL https://chatgpt.com/codex/install.sh | sh || failed=1
      opencode upgrade || failed=1
      # --yes restarts the service, which stops any agent turn still running.
      t3 update --yes || failed=1
      exit "$failed"
    '';
  };
in
{
  home.packages = [
    agents-install
    agents-update
  ];

  # Local models served by llama-swap on homelab-pro (the evo-x2 repo).
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (homelab-pro)";
      options = {
        baseURL = "http://homelab-pro:8080/v1";
        timeout = 900000;
      };
      models = {
        "qwen3.8-27b" = {
          name = "Qwen3.8 27B";
          tool_call = true;
          reasoning = true;
          attachment = true;
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          limit = {
            context = 131072;
            output = 32768;
          };
        };
        "qwen3.8-flash-next" = {
          name = "Qwen3.8 Flash Next";
          tool_call = true;
          reasoning = true;
          attachment = true;
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          limit = {
            context = 131072;
            output = 32768;
          };
        };
        "gemma-4-12b" = {
          name = "Gemma 4 12B";
          tool_call = true;
          limit = {
            context = 32768;
            output = 8192;
          };
        };
      };
    };
    model = "llama-swap/qwen3.8-27b";
    small_model = "llama-swap/gemma-4-12b";
  };

  systemd.user = lib.mkIf config.my.agents.autoUpdate {
    services.agents-update = {
      Unit.Description = "Update the agent CLIs and T3 Code";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe agents-update;
      };
    };
    timers.agents-update = {
      Unit.Description = "Nightly agent CLI and T3 Code update";
      Timer = {
        OnCalendar = "*-*-* 04:30";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
