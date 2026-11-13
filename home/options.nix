{ lib, ... }:
{
  options.my = {
    projectsDir = lib.mkOption {
      type = lib.types.str;
      description = "Where repositories are cloned, relative to $HOME. direnv trusts every .envrc under it.";
    };

    shell.enable = lib.mkEnableOption "zsh, CLI tools and runtimes, for machines no other dotfiles set up";

    git.signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "GPG key that signs commits and tags. Null leaves them unsigned.";
    };

    agents.autoUpdate = lib.mkEnableOption "a nightly update of the agent CLIs and t3, which restarts T3 Code";
  };
}
