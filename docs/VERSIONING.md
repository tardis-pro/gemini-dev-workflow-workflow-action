# Versioning Strategy

This document describes how versioning works for the Navratna DevFlow template.

## Version Format

We use **Semantic Versioning** (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (e.g., workflow interface changes, removed inputs)
- **MINOR**: New features, backward-compatible changes
- **PATCH**: Bug fixes, documentation updates

## Git Tags

Versions are tagged in git:
- `v1.0.0` - First stable release
- `v1.1.0` - Added new feature
- `v1.1.1` - Fixed bug in v1.1.0
- `v2.0.0` - Breaking change

## Consumer Upgrade Path

Consumer repos reference versions via tag:

```yaml
uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
```

### Pinning Strategies

1. **Major version** (recommended for most users):
   ```yaml
   uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
   ```
   - Gets latest v1.x.x automatically
   - Safe: Only receives backward-compatible updates
   - Convenient: Automatic minor/patch updates

2. **Exact version** (for stability-critical projects):
   ```yaml
   uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1.2.3
   ```
   - Frozen: No automatic updates
   - Predictable: Behavior never changes
   - Manual: Must update explicitly

3. **Branch** (for testing/development):
   ```yaml
   uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@main
   ```
   - Latest: Always uses latest commit
   - Risky: May break unexpectedly
   - Only for testing or contributing

## Upgrading

### Check Available Versions

```bash
gh release list --repo tardis-pro/devflow-gemini
```

### Upgrade Process

1. Review [CHANGELOG.md](../CHANGELOG.md) for changes
2. Update workflow file:
   ```diff
   - uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1.0.0
   + uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1.1.0
   ```
3. Test in a non-critical issue first
4. Commit and push

## Breaking Changes

When we release breaking changes (v2.0.0, v3.0.0, etc.), we will:

1. Document migration path in CHANGELOG
2. Provide migration guide
3. Support previous major version for 6 months minimum

## Example: Major Version History

### v1.x → v2.x

**Breaking Changes**:
- Removed `pkg_mgr` input (auto-detected now)
- Renamed `branch_prefix` to `branch_namespace`
- Changed output directory from `ops/out/` to `.devflow/artifacts/`

**Migration**:
```diff
  uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v2
  with:
-   pkg_mgr: pnpm
-   branch_prefix: nav
+   branch_namespace: navratna
```

## Release Process (Maintainers)

1. Update CHANGELOG.md
2. Commit: `git commit -m "chore: release v1.2.0"`
3. Tag: `git tag v1.2.0`
4. Push: `git push origin v1.2.0`
5. Create GitHub release with notes

## Deprecation Policy

Features marked for deprecation:
1. Announced in MINOR release (e.g., v1.5.0)
2. Deprecated in next MAJOR release (e.g., v2.0.0)
3. Removed in following MAJOR release (e.g., v3.0.0)

Minimum 6 months between deprecation and removal.

## Version Support

| Version | Status | Support Until |
|---------|--------|---------------|
| v1.x    | Active | TBD           |

Once v2.x is released:
- v1.x: Security fixes only for 6 months
- v2.x: Active development

## Questions?

Open an issue with the `question` label.
