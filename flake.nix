{
  description = "Home Manager for homelab-pro and the laptop, plus a devenv project template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHome =
        host:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home
            ./hosts/${host}.nix
          ];
        };
    in
    {
      # `home-manager switch --flake .` picks the entry named $USER@$(hostname).
      homeConfigurations = {
        "contessa@homelab-pro" = mkHome "homelab-pro";
        "contessa@arch" = mkHome "arch";
      };

      # The CLI at the version flake.lock pins, for `nix run .#home-manager`.
      packages.${system}.home-manager = home-manager.packages.${system}.default;

      templates.devenv = {
        path = ./templates/devenv;
        description = "devenv dev shell loaded by direnv, with socket-only Postgres and Redis to opt into";
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
