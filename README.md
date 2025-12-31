# cursor-nix

Auto-updating Nix flake for [Cursor](https://cursor.com) - The AI Code Editor.

Fetches directly from Cursor's official apt repository and auto-updates via GitHub Actions.

## Usage

### As a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cursor.url = "github:YOUR_USERNAME/cursor-nix";
    cursor.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, cursor, ... }: {
    # Option 1: Use the overlay
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ cursor.overlays.default ];
          environment.systemPackages = [ pkgs.cursor ];
        }
      ];
    };

    # Option 2: Use the package directly
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [ cursor.packages.x86_64-linux.default ];
        })
      ];
    };
  };
}
```

### Run directly

```bash
nix run github:YOUR_USERNAME/cursor-nix
```

### In home-manager

```nix
home.packages = [ inputs.cursor.packages.x86_64-linux.default ];
```

## Auto-updates

A GitHub Action runs every 6 hours to check Cursor's apt repository for new versions. When found, it:

1. Updates `package.nix` with new version and hash
2. Tests that the build succeeds
3. Creates a PR for review

To enable: push this repo to GitHub and enable Actions.

## Manual update

```bash
./update.sh
```

## License

The packaging is MIT. Cursor itself is proprietary.
