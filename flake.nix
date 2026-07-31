{
  description = "herdr-navigator is a Neovim plugin to handle Neovim-Herdr pane navigation";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-parts, fenix, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ ... }: {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, inputs', ... }: let
        meta = with pkgs.lib; {
          description = "herdr-navigator is a Neovim plugin to handle Neovim-Herdr pane navigation";
          homepage = "https://github.com/joo-was-already-taken/herdr-navigator.nvim";
          license = licenses.mit;
        };
        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        binaryVersion = cargoToml.package.version;
        nvimPluginVersion = let
          versionLua = builtins.readFile ./lua/herdr-navigator/version.lua;
          match = builtins.match ''.*version = "([^"]+)".*'' versionLua;
        in
          if match != null then builtins.head match else null;
        version = assert binaryVersion == nvimPluginVersion; nvimPluginVersion;
      in {
        packages.herdr-navigator = let
          toolchain = inputs'.fenix.packages.stable.withComponents [ "cargo" "rustc" ];
          rustPlatform = pkgs.makeRustPlatform { cargo = toolchain; rustc = toolchain; };
        in rustPlatform.buildRustPackage {
          inherit version meta;
          name = "herdr-navigator";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };

        packages.herdr-navigator-nvim = pkgs.vimUtils.buildVimPlugin {
          inherit version meta;
          pname = "herdr-navigator.nvim";
          src = ./.;
        };

        checks.lua-tests = pkgs.stdenvNoCC.mkDerivation {
          name = "herdr-navigator-nvim-lua-tests";
          src = ./.;
          nativeBuildInputs = [
            pkgs.luajitPackages.busted
          ];
          doCheck = true;
          checkPhase = ''
            busted --verbose spec/
          '';
          installPhase = "touch $out";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            (inputs'.fenix.packages.stable.withComponents [
              "cargo"
              "clippy"
              "rust-src"
              "rustc"
              "rustfmt"
              "rust-analyzer"
            ])
            pkgs.jq
            pkgs.cargo-audit
            pkgs.lua-language-server
            pkgs.luajitPackages.busted
          ];
        };
      };
    });
}
