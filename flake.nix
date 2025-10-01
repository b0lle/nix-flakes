{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-tf = {
      url = "nixpkgs/648f70160c03151bc2121d179291337ad6bc564b"; # v1.12.0
      follows = "nixpkgs";
    };
    nixpkgs-tfdocs = {
      url = "nixpkgs/f3a2a0601e9669a6e38af25b46ce6c4563bcb6da"; # v0.19.0
      follows = "nixpkgs";
    };
    nixpkgs-dbx = {
      url = "nixpkgs/90ade7da38aa49c2e2693a04a44662a0e61530e9"; # v0.269.0
      follows = "nixpkgs";
    };
    nixpkgs-tg = {
      url = "nixpkgs/076e8c6678d8c54204abcb4b1b14c366835a58bb"; # v0.81.7
      follows = "nixpkgs";
    };
    nixpkgs-uv = {
      url = "nixpkgs/648f70160c03151bc2121d179291337ad6bc564b"; # v0.8.2
      follows = "nixpkgs";
    };
    nixpkgs-pre-commit = {
      url = "nixpkgs/f4b140d5b253f5e2a1ff4e5506edbf8267724bde"; # v4.3.0
      follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-tfdocs, nixpkgs-tf, nixpkgs-dbx, nixpkgs-uv
    , nixpkgs-pre-commit, nixpkgs-tg, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # terraform = import nixpkgs-tf {
        #   inherit system;
        #   config = { allowUnfree = true; };
        # };
        # tf-docs = import nixpkgs-tfdocs {
        #   inherit system;
        #   config = { allowUnfree = true; };
        # };
        # tg = import nixpkgs-tg {
        #   inherit system;
        #   config = { allowUnfree = true; };
        # };
        # dbx = import nixpkgs-dbx {
        #   inherit system;
        #   config = { allowUnfree = true; };
        # };
        # uv = import nixpkgs-uv { inherit system; };
        # pre-commit = import nixpkgs-pre-commit { inherit system; };
        p = {
          nixpkgs = nixpkgs.legacyPackages.${system};
          # other-dep would also access `inputs.nixpkgs.legacyPackages.${system}`
          # thus only using a single instance of it.
          terraform-docs = nixpkgs-tfdocs.packages.${system};
          terragrunt = nixpkgs-tg.packages.${system};
          dbx = nixpkgs-dbx.packages.${system};
          uv = nixpkgs-uv.packages.${system};
          pre-commit = nixpkgs-pre-commit.packages.${system};
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            p.terraform
            p.databricks-cli
            p.terragrunt
            p.cowsay
            p.uv
            p.terraform-docs
            p.pre-commit.pre
          ];
          shellHook = ''
            alias tf='terraform'
            alias tg='terragrunt'
            alias dbx='databricks'
            pre-commit install
            echo "Development shell loaded!"
          '';
        };
        devShells.dbxci = pkgs.mkShell {
          packages = [ p.terraform p.databricks-cli p.terragrunt p.uv ];
          shellHook = ''
            alias tf='terraform'
            alias tg='terragrunt'
            alias dbx='databricks'
            echo "databricks shell loaded!"
          '';
        };
      });
}
