# nix-config

Home Manager for my machines, so coding agents on the home server and I on the laptop work in
the same environment:

| Host | Role | Set up by |
|---|---|---|
| `homelab-pro` (Ubuntu) | Always on. Runs T3 Code, Claude Code, Codex and OpenCode, reached from my phone | the `agents` role in [evo-x2](https://github.com/j-ameswong/evo-x2) |
| `arch` (laptop) | In-person work. Also runs T3 Code while it's awake | by hand, below |

Git is the only thing that moves work between them: an agent pushes a branch, I check it out.

## Layers

| Layer | Owner |
|---|---|
| Kernel, drivers, Docker, Tailscale, the Nix daemon | Ansible ([evo-x2](https://github.com/j-ameswong/evo-x2)) or pacman |
| User tools, git, direnv, opencode config, agent updates | this repo (`home/`, `hosts/`) |
| Each project's toolchain, services and environment | `flake.nix` + `devenv.nix` in the project, loaded by direnv |

nixpkgs and Home Manager are pinned in `flake.lock`. The agent CLIs and `t3` are not: they move
faster than nixpkgs, so `agents-install` installs whichever are missing with their own
installers, and each keeps itself current. On `homelab-pro`, a nightly timer (`agents-update`,
04:30) also updates them all, restarting T3 Code.

## Agents and direnv

direnv only loads in interactive shells, and agents run every command in a new non-interactive
one. T3 Code's service sets `BASH_ENV` and `AGENT_SHELL_DIRENV` (via `~/.t3/service.env`), and
the snippets in `~/.config/agent-shell/` then run `direnv export` in each agent shell, so agents
see the same toolchain as an interactive shell in that directory. Every `.envrc` under
`my.projectsDir` and `~/.t3` is trusted without `direnv allow`, because T3 Code starts agents in
new worktrees.

## API keys

OpenCode's DeepSeek and OpenRouter models read `DEEPSEEK_API_KEY` and `OPENROUTER_API_KEY`.
Each lives in its own file, `~/.config/secrets/deepseek.env` and `openrouter.env`, as a plain
`KEY=value` line (systemd can't read `export`). Create them by hand with mode 600; they never
enter git or the Nix store. A drop-in loads them into T3 Code's service
(`t3 service restart` after changing one), and zsh loads them on `homelab-pro`.

## New project

```sh
nix flake init -t ~/Documents/Projects/nix-config#devenv   # or github:j-ameswong/nix-config#devenv
```

Edit `devenv.nix`, then put per-machine values and secrets in `.env.local` (gitignored). The
template's Postgres and Redis listen on Unix sockets only, so parallel worktrees each get their
own.

## Laptop setup

Archdots owns zsh here, so Home Manager leaves it alone. Add to `~/.zshenv`:

```zsh
[[ -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]] && . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
[[ -e ~/.config/agent-shell/env.zsh ]] && . ~/.config/agent-shell/env.zsh
```

and to `~/.zshrc`:

```zsh
eval "$(direnv hook zsh)"
```

Then:

```sh
cd ~/Documents/Projects/nix-config      # `.` below is this flake
nix run .#home-manager -- switch -b hm-backup --flake .
exec zsh               # a new shell, to pick up ~/.nix-profile/bin
agents-install         # only fills in what's missing
```

`-b hm-backup` renames files Home Manager takes over (such as `~/.config/opencode/opencode.json`
and `agents/`) instead of failing. T3 Code needs the API keys in the `.env` form described above. Delete `~/.gitconfig` afterwards; `~/.config/git/config` replaces it.

## Updating

```sh
nix flake update && home-manager switch --flake .   # newer nixpkgs and Home Manager
```

Commit `flake.lock`, then pull and switch on the other machine.
