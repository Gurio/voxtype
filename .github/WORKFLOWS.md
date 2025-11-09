# GitHub Actions Workflows

This project uses GitHub Actions for continuous integration and automated releases.

## Workflows

### 1. CI (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

**What it does:**
- ✅ Builds on Linux, Windows, and macOS
- ✅ Runs TypeScript type checking
- ✅ Runs Rust formatting check (`cargo fmt`)
- ✅ Runs Rust linter (`cargo clippy`)
- ✅ Tests full build process

**Duration:** ~10-15 minutes per platform

### 2. Release (`release.yml`)

**Triggers:**
- Pushing a tag like `v0.1.0`
- Manual workflow dispatch (from Actions tab)

**What it does:**
- 🔨 Builds release binaries for:
  - Linux (x86_64): `.AppImage` and `.deb`
  - Windows (x64): `.msi`
  - macOS (Intel): `.dmg` and `.app`
  - macOS (Apple Silicon): `.dmg` and `.app`
- 📦 Uploads artifacts to the release
- 📝 Generates release notes automatically

**Duration:** ~20-30 minutes total (runs in parallel)

### 3. PR Check (`pr-check.yml`)

**Triggers:**
- Pull request opened, synchronized, or reopened

**What it does:**
- 🔍 Quick TypeScript check
- 🔒 Ensures no `.env` files are committed
- 📦 Validates `package-lock.json` is in sync
- 📊 Checks PR size and warns if too large

**Duration:** ~2-3 minutes

## Creating a Release

### Option 1: Git Tag (Recommended)

```bash
# Update version in package.json and Cargo.toml
npm version patch  # or minor, or major

# Create and push tag
git tag v0.1.1
git push origin v0.1.1
```

The release workflow will automatically:
1. Build for all platforms
2. Create a GitHub release
3. Upload installers
4. Generate release notes

### Option 2: Manual Dispatch

1. Go to **Actions** tab
2. Select **Release** workflow
3. Click **Run workflow**
4. Choose branch and run

## Secrets Required

### Optional (for signed releases):

- `TAURI_PRIVATE_KEY` - Tauri updater private key
- `TAURI_KEY_PASSWORD` - Password for the private key

Generate these with:

```bash
npm run tauri signer generate
```

Then add them to GitHub:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add **New repository secret**

## Workflow Status Badges

Add these to your README.md:

```markdown
[![CI](https://github.com/Gurio/voxtype/actions/workflows/ci.yml/badge.svg)](https://github.com/Gurio/voxtype/actions/workflows/ci.yml)
[![Release](https://github.com/Gurio/voxtype/actions/workflows/release.yml/badge.svg)](https://github.com/Gurio/voxtype/actions/workflows/release.yml)
```

## Troubleshooting

### Build fails on Linux

Make sure system dependencies are installed in the workflow. See `ci.yml` for the list.

### Build fails on macOS

Apple Silicon builds require macOS 11+ runners. The workflow uses `macos-latest`.

### Release doesn't create GitHub release

Check that:
1. Tag starts with `v` (e.g., `v0.1.0`)
2. Tag is pushed to GitHub
3. `GITHUB_TOKEN` has write permissions (should be automatic)

### Artifacts not uploaded

Check the `artifacts` path in `release.yml` matches your build output locations.

## Local Testing

You can test the build process locally before pushing:

```bash
# Test CI build
npm run build

# Test formatting
cd src-tauri && cargo fmt --check

# Test linting
cd src-tauri && cargo clippy
```

## Customization

### Change target platforms

Edit `release.yml` matrix to add/remove platforms:

```yaml
matrix:
  platform:
    - name: Linux ARM64
      os: ubuntu-22.04
      target: aarch64-unknown-linux-gnu
```

### Change Node.js version

Edit all workflow files:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '22'  # Change version here
```

### Add more checks

Add steps to any workflow:

```yaml
- name: Run tests
  run: npm test
```

## Performance Tips

1. **Caching** is enabled for:
   - npm dependencies
   - Rust dependencies
   - Cargo build artifacts

2. **Parallel execution**:
   - Release builds run in parallel for all platforms
   - CI matrix runs in parallel

3. **Fail-fast disabled**:
   - One platform failure won't cancel others
   - You can see all platform issues at once

## Security

- No secrets are logged
- PR checks run on untrusted code (no secrets exposed)
- Release workflow only runs on tags (trusted commits)
- `.env` file check prevents accidental API key commits

## Cost

- GitHub Actions is free for public repositories
- Private repos get 2000 minutes/month free
- Each workflow run uses ~30-50 minutes total across all platforms

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Tauri GitHub Actions Guide](https://tauri.app/v1/guides/building/github-actions)
- [Creating Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)

