{
  description = "Multi-profile development environments with pinned tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Pin terraform to exact version by using a specific nixpkgs commit
    # This commit contains terraform 1.12.0
    # Find commits at: https://www.nixhub.io/ or https://lazamar.co.uk/nix-versions/
    nixpkgs-tf.url =
      "github:NixOS/nixpkgs/4684fd6b0c01e4b7d99027a34c93c2e09ecafee2"; # v1.12.1
    nixpkgs-tfdocs.url =
      "github:nixos/nixpkgs/e6f23dc08d3624daab7094b701aa3954923c6bbb"; # v0.20.0
    nixpkgs-dbx.url =
      "github:nixos/nixpkgs/ee09932cedcef15aaf476f9343d1dea2cb77e261"; # v0.278.0
    nixpkgs-tg.url =
      "github:nixos/nixpkgs/890f57fde071de281cd0e950cd80ea3e1ab55e75"; # v0.93.11
    nixpkgs-uv.url =
      "github:nixos/nixpkgs/821f1a2ebab0f13d6d65170d6bd7d2b3a182efdb"; # v0.9.15
    nixpkgs-pre-commit.url =
      "github:nixos/nixpkgs/f4b140d5b253f5e2a1ff4e5506edbf8267724bde"; # v4.3.0
  };

  outputs = { self, nixpkgs, nixpkgs-tf, nixpkgs-tfdocs, nixpkgs-dbx, nixpkgs-tg
    , nixpkgs-uv, nixpkgs-pre-commit, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        mkPinnedPkgs = input:
          import input {
            inherit system;
            config.allowUnfree = true;
          };
        # Single nixpkgs instance with unfree packages allowed and overlays
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            # Overlay to replace terraform with pinned version
            (final: prev: {
              terraform =
                (mkPinnedPkgs nixpkgs-tf).terraform.withPlugins (p: [ p.time ]);
              terraform-docs = (mkPinnedPkgs nixpkgs-tfdocs).terraform-docs;
              databricks-cli = (mkPinnedPkgs nixpkgs-dbx).databricks-cli;
              terragrunt = (mkPinnedPkgs nixpkgs-tg).terragrunt;
              uv = (mkPinnedPkgs nixpkgs-uv).uv;
              pre-commit = (mkPinnedPkgs nixpkgs-pre-commit).pre-commit;
            })
          ];
        };

        # Common packages used across multiple profiles
        commonTools = with pkgs; [ git curl jq ];

        dbxCiProfile = with pkgs; [
          terraform
          terraform-providers.hashicorp_aws
          terraform-docs
          databricks-cli
          terragrunt
          uv
          pre-commit
        ];

        # Profile-specific package sets
        terraformProfile = with pkgs;
          [
            terraform # Pinned to 1.12.0 via overlay
            terragrunt
            tflint
            awscli2
          ] ++ commonTools;

        # Helper function to create a devShell with custom packages
        mkDevShell = packages:
          pkgs.mkShell {
            buildInputs = packages;

            shellHook = ''
              echo "🚀 Development environment activated!"
              echo "Available profiles: terraform, kubernetes, python, node, full, minimal"
              echo ""
              echo "Versions:"
              ${pkgs.lib.concatMapStringsSep "\n" (pkg:
                if builtins.hasAttr "version" pkg then
                  ''echo "  ${pkg.pname or pkg.name}: ${pkg.version}"''
                else
                  "") packages}
            '';
          };

      in {
        devShells = {
          # Default shell - minimal setup
          default = mkDevShell commonTools;

          dbxci = mkDevShell dbxCiProfile;
          # Terraform + Infrastructure
          terraform = mkDevShell terraformProfile;

          # Minimal shell with just git
          minimal = mkDevShell [ pkgs.git ];
        };

        # Export packages for use in CI or other flakes
        packages = {
          terraform = pkgs.terraform; # Pinned to 1.12.0 via overlay
          kubectl = pkgs.kubectl;
          python = pkgs.python311;
          nodejs = pkgs.nodejs_20;
        };
      });
}
