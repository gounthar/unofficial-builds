# GPG Key Setup Guide for Repository Signing

This guide will help you set up GPG keys for signing APT and RPM repository metadata.

## Option 1: Use Existing Key from docker-dev Repository

If you already have a GPG key for the docker-dev repository, you can reuse it:

### Check if you have the key

```bash
# List existing GPG keys
gpg --list-secret-keys --keyid-format LONG

# Look for the key ID from docker-dev: 56188341425B007407229B48FB1963FC3575A39D
```

If you see this key, skip to **Step 3: Export Key for GitHub Secrets**.

---

## Option 2: Generate a New GPG Key

### Step 1: Generate the Key

```bash
# Generate a new GPG key (RSA 4096 bits, no expiration)
gpg --full-generate-key
```

**When prompted:**
- Key type: `(1) RSA and RSA (default)`
- Key size: `4096`
- Expiration: `0` (key does not expire) - confirm with `y`
- Real name: `Node.js Unofficial Builds`
- Email: `noreply@unofficial-builds.nodejs.org` (or your email)
- Comment: `Repository signing key for riscv64 builds`
- Passphrase: **Choose a strong passphrase** (you'll need this for GitHub secrets)

### Step 2: Verify Key Creation

```bash
# List your keys
gpg --list-secret-keys --keyid-format LONG

# Output should look like:
# sec   rsa4096/ABCDEF1234567890 2025-11-14 [SC]
#       ABCDEF1234567890ABCDEF1234567890ABCDEF12
# uid                 [ultimate] Node.js Unofficial Builds <noreply@unofficial-builds.nodejs.org>
# ssb   rsa4096/1234567890ABCDEF 2025-11-14 [E]
```

**Note the Key ID**: The 40-character fingerprint (e.g., `ABCDEF1234567890ABCDEF1234567890ABCDEF12`)

---

## Step 3: Export Key for GitHub Secrets

### 3.1: Export Private Key

```bash
# Replace YOUR_KEY_ID with your 40-character fingerprint
gpg --armor --export-secret-keys YOUR_KEY_ID > /tmp/gpg-private-key.asc

# Verify the file was created
ls -lh /tmp/gpg-private-key.asc
```

### 3.2: Export Public Key

```bash
# Export public key for users to add to their systems
gpg --armor --export YOUR_KEY_ID > /tmp/gpg-public-key.asc

# Verify the file
ls -lh /tmp/gpg-public-key.asc
```

### 3.3: Note Your Passphrase

Write down or copy the passphrase you used when creating the key. You'll need:
- **GPG_PRIVATE_KEY**: Contents of `/tmp/gpg-private-key.asc`
- **GPG_PASSPHRASE**: The passphrase you set
- **GPG_KEY_ID**: The 40-character fingerprint (or last 16 characters)

---

## Step 4: Add Secrets to GitHub Repository

You have two options to add secrets:

### Option A: Using GitHub Web Interface (Recommended)

1. Go to: [GitHub Actions Secrets](https://github.com/nodejs/nodejs-unofficial-builds/settings/secrets/actions)

2. Click **"New repository secret"**

3. Add three secrets:

   **Secret 1: GPG_PRIVATE_KEY**
   - Name: `GPG_PRIVATE_KEY`
   - Value: Copy the entire content of `/tmp/gpg-private-key.asc`
     ```bash
     cat /tmp/gpg-private-key.asc
     # Copy the output (including -----BEGIN PGP PRIVATE KEY BLOCK----- and -----END PGP PRIVATE KEY BLOCK-----)
     ```

   **Secret 2: GPG_PASSPHRASE**
   - Name: `GPG_PASSPHRASE`
   - Value: Your GPG key passphrase

   **Secret 3: GPG_KEY_ID**
   - Name: `GPG_KEY_ID`
   - Value: Your 40-character key fingerprint (e.g., `ABCDEF1234567890ABCDEF1234567890ABCDEF12`)

### Option B: Using GitHub CLI (gh)

```bash
# Make sure you're in the repository directory
# Add GPG_PRIVATE_KEY
gh secret set GPG_PRIVATE_KEY < /tmp/gpg-private-key.asc

# Add GPG_PASSPHRASE (will prompt for input)
gh secret set GPG_PASSPHRASE

# Add GPG_KEY_ID (will prompt for input)
gh secret set GPG_KEY_ID
```

---

## Step 5: Verify Secrets Were Added

```bash
# List repository secrets (won't show values, just names)
gh secret list

# Expected output:
# GPG_KEY_ID       Updated YYYY-MM-DD
# GPG_PASSPHRASE   Updated YYYY-MM-DD
# GPG_PRIVATE_KEY  Updated YYYY-MM-DD
```

---

## Step 6: Save Public Key for Distribution

The public key needs to be accessible to users. We'll add it to the apt-repo branch later, but for now:

```bash
# Copy public key to the repository (we'll commit it later)
cp /tmp/gpg-public-key.asc ./KEY.gpg
```

---

## Security Notes

1. **Keep the private key secure**: The `/tmp/gpg-private-key.asc` file contains your private key. Delete it after adding to GitHub:
   ```bash
   shred -u /tmp/gpg-private-key.asc
   ```

2. **Backup your key**: Before deleting, consider backing up to a secure location:
   ```bash
   # Export to a secure location
   gpg --armor --export-secret-keys YOUR_KEY_ID > ~/secure-backup/nodejs-unofficial-builds-gpg-private-key.asc
   ```

3. **Public key distribution**: The public key (`KEY.gpg`) will be published on GitHub Pages so users can verify signatures.

---

## Verification Commands

After setup, verify the key is usable:

```bash
# Test signing
echo "test" | gpg --clearsign --armor --local-user YOUR_KEY_ID

# Test verification
echo "test" | gpg --clearsign --armor --local-user YOUR_KEY_ID | gpg --verify
```

---

## Next Steps

Once the GPG secrets are added to GitHub, I'll proceed with:
1. Creating the feature branch
2. Setting up the repository structure
3. Creating the GitHub Actions workflows
4. Creating user documentation

**Ready to proceed?** Let me know when you've added the secrets!

---

## Quick Reference

| Secret Name       | Where to Get It                              | Example Value                           |
|-------------------|----------------------------------------------|-----------------------------------------|
| GPG_PRIVATE_KEY   | `cat /tmp/gpg-private-key.asc`              | `-----BEGIN PGP PRIVATE KEY BLOCK-----` |
| GPG_PASSPHRASE    | The passphrase you set during key generation | `your-secure-passphrase`                |
| GPG_KEY_ID        | `gpg --list-keys --keyid-format LONG`       | `ABCD...1234` (40 chars)                |

---

## Troubleshooting

**Q: I forgot my passphrase**
- You'll need to generate a new key (Option 2)

**Q: Can I use the same key for multiple repositories?**
- Yes! You can reuse the docker-dev key if you have it

**Q: How do I find my key ID?**
```bash
gpg --list-secret-keys --keyid-format LONG | grep sec
# The key ID is after "rsa4096/" or the full fingerprint on the next line
```

**Q: The key file is too large for GitHub secrets**
- GitHub secrets support up to 64KB, which is sufficient for GPG keys
- If you still have issues, ensure you're only copying the private key, not the entire keyring
