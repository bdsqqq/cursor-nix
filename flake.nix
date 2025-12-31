{
  description = "Cursor - The AI Code Editor (auto-updated from apt repo)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        cursor = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          default = cursor;
          cursor = cursor;
        };

        apps.default = {
          type = "app";
          program = "${cursor}/bin/cursor";
        };
      }
    ) // {
      # expose overlay for use in other flakes
      overlays.default = final: prev: {
        cursor = prev.callPackage ./package.nix { };
      };
    };
}
