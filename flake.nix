{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, pkgs, lib, ... }: {
            environment.variables.NFQ_TEST = toString (pkgs.rustPlatform.buildRustPackage {
              name = "nfq-test";
              src = ./nfq-test;
              cargoLock.lockFile = ./nfq-test/Cargo.lock;
            });
            services.getty.autologinUser = "root";
            users.users.test.isNormalUser = true;
          })
        ];
      };
    };
  };
}
