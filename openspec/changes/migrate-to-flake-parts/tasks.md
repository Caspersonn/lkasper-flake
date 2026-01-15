# Implementation Tasks

## 1. Setup and Preparation
- [ ] 1.1 Add flake-parts to flake inputs
- [ ] 1.2 Create parts/ directory structure
- [ ] 1.3 Run `nix flake show` and save output for comparison

## 2. Create flake-parts Modules
- [ ] 2.1 Create parts/systems.nix (define x86_64-linux and aarch64-linux)
- [ ] 2.2 Create parts/formatter.nix (move formatter configuration)
- [ ] 2.3 Create parts/overlays.nix (move overlay logic)
- [ ] 2.4 Create parts/nixos.nix (port makeNixosConf and all 4 nixosConfigurations)
- [ ] 2.5 Create parts/home-manager.nix (port makeHomeConf and all 5 homeConfigurations)

## 3. Update Root Flake
- [ ] 3.1 Update flake.nix to use flake-parts
- [ ] 3.2 Import all parts/ modules
- [ ] 3.3 Remove old monolithic definitions

## 4. Testing and Validation
- [ ] 4.1 Run `nix flake check` to verify flake structure
- [ ] 4.2 Build technative-casper configuration
- [ ] 4.3 Build gaming-casper configuration
- [ ] 4.4 Build server-casper configuration
- [ ] 4.5 Build personal-casper configuration
- [ ] 4.6 Verify home-manager configurations still accessible
- [ ] 4.7 Compare `nix flake show` output with pre-migration
- [ ] 4.8 Test build on at least one physical machine

## 5. Documentation
- [ ] 5.1 Add comments in parts/ modules explaining structure
- [ ] 5.2 Update openspec/project.md to mention flake-parts usage
