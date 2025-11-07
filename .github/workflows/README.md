## GitHub Actions Workflows

This directory contains automated workflows for building Node.js binaries.

### native-riscv64-build.yml

Automatically builds Node.js binaries natively on RISC-V 64-bit hardware using a self-hosted GitHub Actions runner.

#### Features

- **Scheduled Builds**: Runs daily at 02:00 UTC to check for new Node.js releases
- **Manual Builds**: Can be triggered manually via workflow_dispatch with version selection
- **Automatic Releases**: Creates GitHub releases with built binaries as downloadable assets
- **Native Compilation**: Builds directly on riscv64 hardware (not cross-compiled)
- **ccache Optimization**: Reuses compiled objects for faster subsequent builds

#### Architecture

Unlike the SSH orchestration used in manual builds, this workflow runs **directly on the riscv64 GitHub runner**:

1. Runner detects new Node.js releases
2. Downloads source tarball
3. Builds locally using native gcc
4. Creates GitHub releases with binaries

**No SSH needed** - the runner IS the build machine!

#### Requirements

##### Self-Hosted Runner

This workflow requires a self-hosted GitHub Actions runner running **on your riscv64 machine**:

- **Architecture**: RISC-V 64-bit (riscv64)
- **OS**: Linux (tested on Debian 13)
- **Labels**: `self-hosted`, `Linux`, `RISCV64`
- **Network**: Can be on a private network (no inbound access needed)

##### Required Tools

The runner must have these tools installed:

```bash
sudo apt-get update
sudo apt-get install -y gcc g++ make python3 git ccache xz-utils curl
```

##### Runner Setup

Follow the [GitHub Actions self-hosted runner documentation](https://docs.github.com/en/actions/hosting-your-own-runners) to install the runner on your riscv64 machine.

**Key steps:**
1. Go to your repo → Settings → Actions → Runners → New self-hosted runner
2. Select Linux and follow the download/configure instructions
3. Add the labels: `self-hosted`, `Linux`, `RISCV64`
4. Start the runner service

##### No Secrets Required!

Since the workflow runs directly on the build machine, **no SSH secrets are needed**. The runner has local access to everything.

#### Usage

##### Automatic Builds (Scheduled)

The workflow runs automatically every day at 02:00 UTC. It will:
1. Check for new Node.js **LTS** releases from nodejs.org (by default)
2. Compare with existing releases in this repository
3. Build any new versions natively on riscv64 hardware
4. Create GitHub releases with the built binaries

**Note:** Scheduled builds default to `lts_only: true`, focusing on production-ready Long Term Support versions. To build all versions, use manual workflow dispatch with `lts_only: false`.

##### Manual Builds

To trigger a manual build:

1. Go to Actions → Native RISC-V 64 Build
2. Click "Run workflow"
3. Optionally specify:
   - **version**: Specific Node.js version (e.g., `v24.11.0`)
   - **force_rebuild**: Check to rebuild even if release exists
   - **lts_only**: Only build LTS versions (default: `true`)

**Examples:**
- Build latest LTS releases: Leave version empty, run workflow (default)
- Build specific version: Enter `v24.11.0` in version field
- Build all versions (including non-LTS): Uncheck "lts_only"
- Rebuild existing: Enter version and check "force_rebuild"

#### Workflow Steps

1. **check-releases**: Detects new Node.js versions to build
2. **build**: Compiles Node.js natively on the riscv64 runner
   - Runs one build at a time (max-parallel: 1)
   - Uses `bin/test_native_build.sh` script
   - Generates checksums (SHASUMS256.txt)
3. **Create Release**: Publishes binaries as GitHub releases
   - Includes both .tar.gz and .tar.xz formats
   - Adds detailed release notes
   - Includes SHA256 checksums
4. **summary**: Generates workflow summary

#### Build Artifacts

Each successful build produces:
- `node-{version}-linux-riscv64.tar.gz` - Gzip compressed tarball
- `node-{version}-linux-riscv64.tar.xz` - XZ compressed tarball (smaller)
- `SHASUMS256.txt` - SHA256 checksums for verification
- Build logs (uploaded as workflow artifacts, 30-day retention)

#### Monitoring

- **Workflow runs**: Check the Actions tab for status
- **Releases**: View created releases in the Releases section
- **Logs**: Download build logs from workflow artifacts for debugging

#### Troubleshooting

##### Runner Not Available

If the workflow can't find a runner:
1. Check runner status: Settings → Actions → Runners
2. Ensure runner is online and has correct labels
3. Restart runner service if needed:
   ```bash
   cd ~/actions-runner
   ./run.sh
   ```

##### Build Fails

1. Check workflow logs in the Actions tab
2. Download build log artifacts for detailed error messages
3. Test build manually on the runner:
   ```bash
   cd ~/nodejs-builds/staging
   curl -LO https://nodejs.org/dist/v24.11.0/node-v24.11.0.tar.xz
   tar -xf node-v24.11.0.tar.xz
   cd node-v24.11.0
   export CC="ccache gcc"
   export CXX="ccache g++"
   make -j$(nproc) binary CONFIG_FLAGS="--openssl-no-asm"
   ```

##### Disk Space Issues

The workflow automatically cleans up extracted source after each build, but you may need to manually clean ccache:
```bash
export CCACHE_DIR="$HOME/nodejs-builds/ccache"
ccache -C  # Clear all cache
ccache -c  # Clean old entries
```

##### No New Versions Found

The workflow checks the latest 5 Node.js releases. If all are already built, it will skip. This is normal behavior.

#### Customization

##### Change Schedule

Edit the cron expression in the workflow file:
```yaml
schedule:
  - cron: '0 2 * * *'  # Daily at 02:00 UTC
```

Common patterns:
- `'0 */6 * * *'` - Every 6 hours
- `'0 0 * * 0'` - Weekly on Sunday at midnight
- `'0 0 1 * *'` - Monthly on the 1st

##### Build More/Fewer Versions

Modify the `head -5` in the check-releases step to change how many recent versions are checked:
```bash
head -10  # Check latest 10 versions
```

##### Filter Versions

**LTS Filtering (Built-in):**

The workflow includes built-in LTS filtering via the `lts_only` parameter:
- **Default**: Only builds LTS versions (recommended for production)
- **Disable**: Set `lts_only: false` in workflow_dispatch to build all versions
- **Detection**: Checks column 10 in nodejs.org index.tab for LTS codename

LTS versions have codenames (e.g., "Krypton", "Hydrogen"), while non-LTS versions have "-".

**Custom Filtering:**

For additional filtering, modify the check-releases step to filter by specific major versions or custom criteria.

#### Security Notes

- Runner operates on a private network (no inbound access needed)
- Only outbound HTTPS to GitHub and nodejs.org
- No secrets required (builds locally)
- Regularly update dependencies on the runner machine
- Consider running runner as a dedicated user (not root)

#### Related Documentation

- [Native RISC-V Build Recipe](../../recipes/riscv64-native/README.md)
- [Setup Guide](../../docs/native-riscv64-build-setup.md)
- [Main README](../../README.md)
