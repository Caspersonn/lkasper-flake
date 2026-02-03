# Proposed Structural Changes - For Review

## Summary

Simplify the dendritic module structure to be cleaner and more maintainable:

1. **Flat file structure** - No subdirectories per module
2. **Remove all [N]/[D] markers** - Clean names only
3. **Service categorization via comments** - Not subdirectories

## Changes Required

### 1. Flat File Structure

**Current Structure** (nested):
```
modules/services/atuin [N]/atuin.nix
modules/services/docker [N]/docker.nix
modules/programs/cli/tools [N]/tools.nix
modules/system/locale [N]/locale.nix
modules/users/casper [N]/casper.nix
```

**New Structure** (flat):
```
modules/services/atuin.nix
modules/services/docker.nix
modules/programs/cli/tools.nix
modules/system/locale.nix
modules/users/casper.nix
```

**Exception**: Hosts keep subdirectories (have multiple files):
```
modules/hosts/gaming-casper/
├── flake-parts.nix
├── configuration.nix
└── hardware.nix
```

**Implementation**:
- Move all `<name> [N]/<name>.nix` → `<name>.nix`
- Keep subdirectories only for logical grouping: `programs/cli/`, `programs/desktop/`, `programs/dev/`, etc.

### 2. Remove [N]/[D]/[ND] Markers

**Current**:
```
modules/services/docker [N]/
modules/programs/desktop/hyprland [N]/
modules/hosts/gaming-casper [N]/
modules/users/casper [N]/
```

**New**:
```
modules/services/docker.nix
modules/programs/desktop/hyprland.nix
modules/hosts/gaming-casper/
modules/users/casper.nix
```

**Rationale**:
- Platform information is in module content, not needed in name
- Cleaner appearance
- Less visual noise
- Standard Nix convention

### 3. Service Organization

**Current**: Flat with [N] subdirectories
```
modules/services/
├── atuin [N]/atuin.nix
├── docker [N]/docker.nix
├── tailscale [N]/tailscale.nix
├── mysql [N]/mysql.nix
└── (23 total services)
```

**Proposed**: Organized by functional subdirectories
```
modules/services/
├── development/
│   ├── docker.nix
│   ├── podman.nix
│   └── atuin.nix
│
├── networking/
│   ├── tailscale.nix
│   ├── openvpn.nix
│   ├── wireguard.nix
│   └── resolved.nix
│
├── sync/
│   ├── syncthing.nix
│   ├── syncthing-server.nix
│   └── smb.nix
│
├── database/
│   ├── mysql.nix
│   └── neo4j.nix
│
├── monitoring/
│   ├── monitoring.nix
│   ├── nix-healthchecks.nix
│   └── coolerd.nix
│
├── media/
│   ├── bluetooth-receiver.nix
│   ├── printing.nix
│   └── ollama.nix
│
├── system/
│   ├── fwupd.nix
│   └── flatpak.nix
│
├── communication/
│   ├── croctalk.nix
│   └── birthday.nix
│
└── misc/
    └── docker-stremio.nix
```

**Rationale**:
- Clear functional grouping
- Easy to find related services
- One level of nesting (not too deep)
- Logical organization
- Extensible for future services

## Benefits

### Flat File Structure
- ✅ Cleaner `ls` output
- ✅ Simpler file paths
- ✅ Easier navigation
- ✅ Less directory depth
- ✅ Faster to find modules
- ✅ Standard Nix convention

### Remove [N]/[D] Markers
- ✅ Cleaner appearance
- ✅ Less visual clutter
- ✅ Easier to read
- ✅ Platform info in module, not name

### Comment-Based Categorization
- ✅ Easy to scan services
- ✅ Clear organization
- ✅ No directory overhead
- ✅ Simple to add new services
- ✅ Follows mipnix pattern

## Migration Effort

### Automated Changes (Low Effort)
1. **Flatten directories**: Move files from subdirectories to parent
   ```bash
   # For each module
   mv "modules/services/atuin [N]/atuin.nix" "modules/services/atuin.nix"
   rmdir "modules/services/atuin [N]"
   ```

2. **Add category comments**: Add comment headers to services file listing
   ```bash
   # Prepend comments to categorize services
   # Can be done with sed/awk or manually
   ```

### Manual Changes (Low-Medium Effort)
- Verify all imports still work after moves
- Test that import-tree discovers all modules
- Update any documentation referencing old paths

### Testing Required
- ✅ All 4 hosts must still build
- ✅ `nix eval .#modules.nixos --apply builtins.attrNames` shows all modules
- ✅ No broken imports

## Estimated Time
- **Automated moves**: 30 minutes
- **Testing**: 30 minutes
- **Documentation updates**: 15 minutes
- **Total**: ~1.5 hours

## Questions for Review

1. **Flat file structure**: Approved? Any modules that should keep subdirectories?
2. **[N]/[D] removal**: Approved for all modules?
3. **Service categorization**: Approved with comments? Prefer different categories?
4. **Alternative**: Want subdirectories for services instead (e.g., `services/networking/`, `services/databases/`)?

## Reference

- **mipnix services**: https://github.com/mipmip/mipnix/tree/main/modules/services (all flat)
- **mipnix system**: https://github.com/mipmip/mipnix/tree/main/modules/system (all flat)

## Next Steps After Approval

1. Update `design.md` with Decisions 16 & 17 ✅ (already done)
2. Update `proposal.md` with structural changes ✅ (already done)
3. Implement changes:
   - Flatten all module directories
   - Remove [N]/[D] markers
   - Add service category comments
   - Test all hosts build
4. Update documentation
5. Commit changes
