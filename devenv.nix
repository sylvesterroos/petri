{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  pkgsUnstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };

  # https://nixos.org/manual/nixpkgs/stable/#beam-structure
  beamPackages = pkgsUnstable.beam29Packages.extend (self: super: { elixir = self.elixir_1_20; });
  erlang = beamPackages.erlang;
  elixir = beamPackages.elixir;
in
{
  dotenv.enable = false;
  dotenv.disableHint = true;

  env = rec {
    # Prevents conflicts with elixir versions installed otherwise
    MIX_HOME = "${config.git.root}/.mix";
    MIX_ARCHIVES = "${MIX_HOME}/archives";
    HEX_HOME = "${config.git.root}/.hex";

    # Erlang shell history and distributed cookie
    ERL_AFLAGS = "-kernel shell_history enabled -setcookie petri";
  };

  enterShell = /* bash */ ''
    mix local.hex --if-missing --force
    mix local.rebar --if-missing --force
  '';

  scripts.remsh.exec = ''
    ${elixir}/bin/iex --sname petri-iex --remsh petri@"$(hostname -s)" "$@"
  '';

  packages =
    with pkgs;
    [
      # expert-lsp needs the erlang binary
      erlang

      # SVG rasterization + WebP animation assembly
      librsvg
      ffmpeg

      nixfmt
    ]
    ++ lib.optionals stdenv.isLinux (
      with pkgs;
      [
        # phoenix_live_reload + ExUnit Notifier
        inotify-tools
        libnotify
      ]
    )
    ++ lib.optionals stdenv.isDarwin (
      with pkgs;
      [
        # ExUnit Notifier
        terminal-notifier
      ]
    );

  languages = {
    nix = {
      enable = true;
      lsp = {
        enable = true;
        package = pkgs.nil;
      };
    };

    elixir = {
      enable = true;
      package = elixir;
      lsp.enable = false;
    };
  };

  processes.tidewave = {
    cwd = config.git.root;
    exec = /* bash */ "mix tidewave";
  };

  # See full reference at https://devenv.sh/reference/options/
}
