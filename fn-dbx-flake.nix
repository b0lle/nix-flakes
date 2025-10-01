{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-tf.url =
      "nixpkgs/648f70160c03151bc2121d179291337ad6bc564b"; # v1.12.0
    nixpkgs-dbx.url =
      "nixpkgs/90ade7da38aa49c2e2693a04a44662a0e61530e9"; # v0.269.0
    nixpkgs-tg.url =
      "nixpkgs/076e8c6678d8c54204abcb4b1b14c366835a58bb"; # v0.81.7
  };

  outputs = { nixpkgs, nixpkgs-tf, nixpkgs-dbx, nixpkgs-tg, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        terraform = import nixpkgs-tf {
          inherit system;
          config = { allowUnfree = true; };
        };
        dbx = import nixpkgs-dbx {
          inherit system;
          config = { allowUnfree = true; };
        };
      in {
        devShells.default = pkgs.mkShell {
          packages =
            [ terraform.terraform dbx.databricks-cli nixpkgs-tg.terragrunt ];
        };
      });
}
