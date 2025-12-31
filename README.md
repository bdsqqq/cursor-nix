# cursor-nix

auto-updating nix flake for [Cursor](https://cursor.com) — the AI code editor.

fetches directly from cursor's official apt repository and auto-updates via github actions every 6 hours.

## usage

### as a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cursor.url = "github:bdsqqq/cursor-nix";
    cursor.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, cursor, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [ 
            cursor.packages.x86_64-linux.default 
          ];
        })
      ];
    };
  };
}
```

### with home-manager

```nix
{ inputs, ... }: {
  home.packages = [ inputs.cursor.packages.x86_64-linux.default ];
}
```

### run directly

```bash
nix run github:bdsqqq/cursor-nix
```

## auto-updates

a github action runs every 6 hours to check cursor's apt repository for new versions. when found, it:

1. updates `package.nix` with new version and hash
2. tests that the build succeeds  
3. creates a PR and auto-merges it

## manual update

```bash
./update.sh
```

## why this exists

cursor releases multiple times per week. the nixpkgs `code-cursor` package lags behind and the maintainer stepped back. this flake:

- pulls from cursor's official apt repo (same source as `apt install cursor`)
- auto-updates without manual intervention
- builds and tests before merging

## license

packaging is MIT. cursor itself is proprietary.
