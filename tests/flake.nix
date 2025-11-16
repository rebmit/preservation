{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem = { pkgs, ... }:
          {
            checks = {
              default = pkgs.testers.nixosTest (import ./basic.nix pkgs);
              firstboot-bind-mount = pkgs.testers.nixosTest (import ./firstboot-bind-mount.nix pkgs);
              firstboot-symlink = pkgs.testers.nixosTest (import ./firstboot-symlink.nix pkgs);
              verity-image = pkgs.testers.nixosTest (import ./appliance-image-verity.nix pkgs);
            };
          };
      };
}
