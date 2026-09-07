# waterfox-flake

Nix flake packaging [Waterfox](https://www.waterfox.com) for NixOS.

## Quick Run

```bash
nix run github:b1tflyyyy/waterfox-flake
```

## Installation

### 1. Add to `flake.nix`

Add `waterfox` to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    waterfox = {
      url = "github:b1tflyyyy/waterfox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Add to `configuration.nix` (or `home.nix`)

Add the package to `environment.systemPackages`:

```nix
{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.waterfox.packages.${pkgs.system}.default
  ];
}
```

Or if you manage user packages via Home Manager (`home.nix`):

```nix
{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.waterfox.packages.${pkgs.system}.default
  ];
}
```

## Supported Architectures

- `x86_64-linux`
- `aarch64-linux`