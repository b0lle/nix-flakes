{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, other-dep }: {
    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
      let p = inputs.nixpkgs.legacyPackages.${system};
      in {
        devShells = {
          default = p.mkShell {
            packages = [
              p.terraform
              p.databricks-cli
              p.terragrunt
              p.cowsay
              p.uv
              p.terraform-docs
              p.pre-commit
            ];
            shellHook = ''
              alias tf='terraform'
              alias tg='terragrunt'
              alias dbx='databricks'
              pre-commit install
              echo "Development shell loaded!"
            '';
          };
        };
      });
  };
}
