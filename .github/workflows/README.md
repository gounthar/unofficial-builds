## GitHub Actions Workflows

This directory contains automated workflows for building Node.js binaries.

### native-riscv64-build.yml

Automatically builds Node.js binaries natively on RISC-V 64-bit hardware using a self-hosted GitHub Actions runner.

#### Features

- **Scheduled Builds**: Runs daily at 02:00 UTC to check for new Node.js releases
- **Manual Builds**: Can be triggered manually via workflow_dispatch with version selection
- **Automatic Releases**: Creates GitHub releases with built binaries as downloadable assets
- **Native Compilation**: Builds on actual riscv64 hardware (not cross-compiled)

#### Requirements

##### Self-Hosted Runner

This workflow requires a self-hosted GitHub Actions runner with:
- **Architecture**: RISC-V 64-bit (riscv64)
- **OS**: Linux (tested on Debian 13)
- **Labels**: `self-hosted`, `Linux`, `RISCV64`
- **SSH Access**: Runner must have SSH access to the remote build machine

To set up the runner, follow the [GitHub Actions self-hosted runner documentation](https://docs.github.com/en/actions/hosting-your-own-runners).

##### Repository Secrets

Configure these secrets in your repository settings (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `RISCV64_REMOTE_HOST` | IP address or hostname of the remote riscv64 build machine | `192.168.1.185` |
| `RISCV64_REMOTE_USER` | SSH username for the remote machine | `poddingue` |
| `RISCV64_REMOTE_BUILD_DIR` | Build directory on remote machine (optional, defaults to `nodejs-builds`) | `nodejs-builds` |

##### SSH Key Setup

The self-hosted runner must have SSH key authentication set up to access the remote build machine:

```bash
# On the runner machine
ssh-keygen -t ed25519 -f ~/.ssh/id_riscv64_build
ssh-copy-id -i ~/.ssh/id_riscv64_build ${RISCV64_REMOTE_USER}@${RISCV64_REMOTE_HOST}

# Test connection
ssh -i ~/.ssh/id_riscv64_build ${RISCV64_REMOTE_USER}@${RISCV64_REMOTE_HOST} "echo 'Connected'"
```

#### Usage

##### Automatic Builds (Scheduled)

The workflow runs automatically every day at 02:00 UTC. It will:
1. Check for new Node.js releases from nodejs.org
2. Compare with existing releases in this repository
3. Build any new versions natively on riscv64 hardware
4. Create GitHub releases with the built binaries

##### Manual Builds

To trigger a manual build:

1. Go to Actions → Native RISC-V 64 Build
2. Click "Run workflow"
3. Optionally specify:
   - **version**: Specific Node.js version (e.g., `v24.11.0`)
   - **force_rebuild**: Check to rebuild even if release exists

**Examples:**
- Build latest releases: Leave version empty, run workflow
- Build specific version: Enter `v24.11.0` in version field
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

##### SSH Connection Fails

```bash
# On runner machine, test SSH manually
ssh ${RISCV64_REMOTE_USER}@${RISCV64_REMOTE_HOST} "echo 'Test'"

# Check SSH agent
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/id_riscv64_build
```

##### Build Fails

1. Check workflow logs in the Actions tab
2. Download build log artifacts for detailed error messages
3. Test build manually on the runner:
   ```bash
   export RISCV64_REMOTE_HOST="192.168.1.185"
   export RISCV64_REMOTE_USER="poddingue"
   export RISCV64_REMOTE_BUILD_DIR="nodejs-builds"
   bash bin/test_native_build.sh -v v24.11.0
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

Add version filtering logic in the check-releases step to only build specific major versions, LTS releases, etc.

#### Security Notes

- SSH keys on the runner should be dedicated to builds (not your personal keys)
- Limit SSH key permissions on the remote machine if possible
- Keep the remote build machine on a trusted network
- Regularly update dependencies on both runner and remote machine
- Repository secrets are encrypted and only exposed to workflow runs

#### Related Documentation

- [Native RISC-V Build Recipe](../../recipes/riscv64-native/README.md)
- [Setup Guide](../../docs/native-riscv64-build-setup.md)
- [Main README](../../README.md)
