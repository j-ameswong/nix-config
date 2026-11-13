{ config, lib, ... }:
let
  signingKey = config.my.git.signingKey;
  signs = signingKey != null;
in
{
  programs.git = {
    enable = true;
    ignores = [ "**/.claude/settings.local.json" ];
    signing = lib.mkIf signs {
      key = signingKey;
      format = "openpgp";
      signByDefault = true;
      # The system gpg, so it talks to the gpg-agent the desktop session already runs.
      signer = "gpg";
    };
    settings = {
      user = {
        name = "Cheng An Wong";
        email = "wongchengan@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      diff.tool = "nvimdiff";
      tag.gpgSign = signs;
    };
  };

  # `gh auth login` once per machine; git then pushes over HTTPS with that token.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
