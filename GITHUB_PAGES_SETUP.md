# GitHub Pages Setup Instructions

To complete the repository setup, you need to enable GitHub Pages for the `apt-repo` branch.

## Step 1: Navigate to Repository Settings

Go to: https://github.com/gounthar/nodejs-unofficial-builds/settings/pages

## Step 2: Configure GitHub Pages

1. Under "Build and deployment":
   - **Source**: Select "Deploy from a branch"

2. Under "Branch":
   - **Branch**: Select `apt-repo` from the dropdown
   - **Folder**: Select `/ (root)`

3. Click **Save**

## Step 3: Wait for Deployment

GitHub Pages will build and deploy the site. This usually takes 1-2 minutes.

You can monitor the deployment:
- Go to: https://github.com/gounthar/nodejs-unofficial-builds/actions
- Look for the "pages build and deployment" workflow

## Step 4: Verify Deployment

Once deployed, verify the repository is accessible:

```bash
# Check if the GPG key is accessible
curl -I https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg

# Should return: HTTP/2 200
```

## Step 5: Test APT Repository (Optional)

If you want to test the repository before adding packages:

```bash
# Try to fetch the (currently empty) package index
curl https://gounthar.github.io/nodejs-unofficial-builds/dists/trixie/main/binary-riscv64/Packages

# This will return 404 until the first package is added
```

## Next Steps

After GitHub Pages is enabled:

1. **Return to main branch**:
   ```bash
   git checkout main
   ```

2. **Create a Pull Request** for the feature branch:
   ```bash
   gh pr create \
     --base main \
     --head feature/apt-yum-repository-setup \
     --title "feat: add APT and RPM repository infrastructure" \
     --body "$(cat <<'EOF'
   Add complete repository infrastructure for distributing Node.js builds via package managers.

   ## Summary

   This PR adds APT (Debian/Ubuntu) and RPM (Fedora/RHEL) repository infrastructure to enable users to install Node.js via package managers instead of manual downloads.

   ## Changes

   - ✅ Created `apt-repo` branch for hosting repository metadata via GitHub Pages
   - ✅ Added `update-apt-repo.yml` workflow to maintain Debian repository
   - ✅ Added `update-rpm-repo.yml` workflow to maintain RPM repository
   - ✅ Added GPG key configuration and secrets
   - ✅ Added comprehensive user documentation

   ## Repository Structure

   **apt-repo branch** (served via GitHub Pages):
   - APT: `dists/trixie/main/binary-riscv64/` with GPG-signed Release
   - RPM: `rpm/fedora/riscv64/` with signed repomd.xml
   - GPG public key for verification
   - YUM/DNF repository configuration file

   ## Installation

   Once this is merged and packages are published, users can install via:

   **APT (Debian/Ubuntu)**:
   \`\`\`bash
   curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg | \\
     sudo gpg --dearmor -o /etc/apt/keyrings/nodejs-unofficial.gpg

   echo "deb [arch=riscv64 signed-by=/etc/apt/keyrings/nodejs-unofficial.gpg] https://gounthar.github.io/nodejs-unofficial-builds trixie main" | \\
     sudo tee /etc/apt/sources.list.d/nodejs-unofficial.list

   sudo apt update
   sudo apt install nodejs
   \`\`\`

   **DNF/YUM (Fedora/RHEL)**:
   \`\`\`bash
   sudo curl -o /etc/yum.repos.d/nodejs-unofficial.repo \\
     https://gounthar.github.io/nodejs-unofficial-builds/nodejs-unofficial.repo

   sudo dnf install nodejs
   \`\`\`

   ## Automatic Updates

   The workflows are triggered when:
   - A new release is published (automatic)
   - Manually via workflow_dispatch

   ## Testing

   After merging, trigger the workflows manually to test:
   \`\`\`bash
   # Trigger APT repository update
   gh workflow run update-apt-repo.yml -f version=v24.11.0

   # Trigger RPM repository update
   gh workflow run update-rpm-repo.yml -f version=v24.11.0
   \`\`\`

   ## Documentation

   - See \`REPOSITORY_INSTALLATION.md\` for user installation instructions
   - See \`GPG_KEY_SETUP_GUIDE.md\` for maintainer setup guide

   ## Prerequisites

   - ✅ GitHub secrets configured (GPG_PRIVATE_KEY, GPG_PASSPHRASE, GPG_KEY_ID)
   - ⏳ GitHub Pages enabled for apt-repo branch (manual step required)

   ## Related Issues

   Implements repository-based distribution as discussed.
   EOF
   )"
   ```

3. **Test the workflows** after merging:
   - The workflows should trigger automatically on new releases
   - You can also test manually by running them with workflow_dispatch

## Troubleshooting

### Pages not deploying

If GitHub Pages doesn't deploy:
- Check that the apt-repo branch exists
- Ensure you selected the correct branch and folder
- Check the Actions tab for deployment errors

### 404 errors

Until packages are added via the workflows, some paths will return 404:
- `dists/trixie/main/binary-riscv64/Packages` - Normal, created by workflow
- `rpm/fedora/riscv64/repodata/` - Normal, created by workflow

These paths are accessible:
- `KEY.gpg` - GPG public key
- `nodejs-unofficial.repo` - YUM/DNF configuration
- `README.md` - Repository documentation

## Repository URL

Once enabled, the repository will be available at:
- **URL**: https://gounthar.github.io/nodejs-unofficial-builds
- **GPG Key**: https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg
- **YUM Config**: https://gounthar.github.io/nodejs-unofficial-builds/nodejs-unofficial.repo
