{ den, ... }: {
  den.aspects.wezterm = {
    homeManager = { ... }: {
      programs.wezterm.enable = true;

      xdg.configFile."wezterm".source = ./config;

      programs.zsh.shellAliases.wezterm-dev = "wezterm --config-file \"\${NIX_CONFIG_DIR:-$HOME/nix-config}/modules/wezterm/config/wezterm.lua\" start --always-new-process";
    };
  };
}
