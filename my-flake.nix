{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-tf.url =
      "github:nixos/nixpkgs/648f70160c03151bc2121d179291337ad6bc564b"; # v1.12.0
    nixpkgs-tfdocs.url =
      "github:nixos/nixpkgs/f3a2a0601e9669a6e38af25b46ce6c4563bcb6da"; # v0.19.0
    nixpkgs-dbx.url =
      "github:nixos/nixpkgs/90ade7da38aa49c2e2693a04a44662a0e61530e9"; # v0.269.0
    nixpkgs-tg.url =
      "github:nixos/nixpkgs/076e8c6678d8c54204abcb4b1b14c366835a58bb"; # v0.81.7
    nixpkgs-uv.url =
      "github:nixos/nixpkgs/648f70160c03151bc2121d179291337ad6bc564b"; # v0.8.2
    nixpkgs-pre-commit.url =
      "github:nixos/nixpkgs/f4b140d5b253f5e2a1ff4e5506edbf8267724bde"; # v4.3.0
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, nixpkgs-tf, nixpkgs-tfdocs, nixpkgs-dbx, nixpkgs-tg
    , nixpkgs-uv, nixpkgs-pre-commit, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              terraform = (import nixpkgs-tf {
                inherit system;
                config = { allowUnfree = true; };
              }).terraform;
              terraform-docs =
                (import nixpkgs { inherit system; }).terraform-docs;
              terragrunt = (import nixpkgs-tg { inherit system; }).terragrunt;
              databricks-cli = (import nixpkgs-dbx {
                inherit system;
                config = { allowUnfree = true; };

              }).databricks-cli;
              uv = (import nixpkgs-uv { inherit system; }).uv;
              pre-commit =
                (import nixpkgs-pre-commit { inherit system; }).pre-commit;
            })
          ];
        };
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = [
              pkgs.terraform
              pkgs.databricks-cli
              pkgs.terragrunt
              pkgs.terraform-docs
              pkgs.uv
              pkgs.pre-commit
            ];
            shellHook = ''
              alias tf='terraform'
              alias tg='terragrunt'
              alias dbx='databricks'
              pre-commit install
              echo "Development shell loaded!"
            '';
          };

          dbxci = pkgs.mkShell {
            packages =
              [ pkgs.terraform pkgs.databricks-cli pkgs.terragrunt pkgs.uv ];
            shellHook = ''
              alias tf='terraform'
              alias tg='terragrunt'
              alias dbx='databricks'
              echo "databricks shell loaded!"
            '';
          };
        };
      });
}
