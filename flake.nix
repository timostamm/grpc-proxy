{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    flocken = {
      url = "github:mirkolenz/flocken/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    systems,
    flocken,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      perSystem = {
        pkgs,
        system,
        lib,
        self',
        ...
      }: {
        apps = {
          dockerManifest = {
            type = "app";
            program = lib.getExe (flocken.legacyPackages.${system}.mkDockerManifest {
              branch = builtins.getEnv "GITHUB_REF_NAME";
              name = "ghcr.io/" + builtins.getEnv "GITHUB_REPOSITORY";
              version = builtins.getEnv "VERSION";
              images = with self.packages; [x86_64-linux.docker aarch64-linux.docker];
            });
          };
          default = {
            type = "app";
            program = lib.getExe self'.packages.default;
          };
        };
        packages = {
          default = pkgs.callPackage ./. {
            env = rec {
              PROXY_HOST = "127.0.0.1";
              ADMIN_HOST = PROXY_HOST;
              BACKEND_HOST = PROXY_HOST;
            };
          };
          grpc-proxy = self'.packages.default;
          docker = pkgs.callPackage ./docker.nix {};
        };
      };
    };
}
