# https://devenv.sh/reference/options/
{ pkgs, ... }:
{
  packages = [ pkgs.git ];

  # languages.javascript = {
  #   enable = true;
  #   package = pkgs.nodejs_24;
  #   npm.enable = true;
  # };

  # Plain variables. Secrets go in .env.local, which .envrc loads and git ignores.
  # env.LOG_LEVEL = "debug";

  # Started by `devenv up`. Unix sockets only, under .devenv, so each worktree an agent
  # starts gets its own database and none of them fight over ports. PGHOST and
  # REDIS_UNIX_SOCKET point at the sockets.
  # services.postgres = {
  #   enable = true;
  #   listen_addresses = "";
  #   initialDatabases = [ { name = "app"; } ];
  # };
  # services.redis = {
  #   enable = true;
  #   port = 0;
  # };
}
