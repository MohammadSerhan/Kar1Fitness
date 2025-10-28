# Fix GitHub Authentication Error

## Problem
Git is using cached credentials from "MohammadPicTime" instead of "MohammadSerhan"

## Solution 1: Clear Cached Credentials (Recommended)

### Step 1: Remove GitHub credentials from Windows
1. Press `Windows Key + R`
2. Type: `control /name Microsoft.CredentialManager`
3. Click "OK"
4. Click on "Windows Credentials"
5. Scroll down to "Generic Credentials"
6. Find and expand any entry that contains "github"
7. Click "Remove" for each GitHub entry
8. Close Credential Manager

### Step 2: Try pushing again
Open Git Bash and run:
```bash
cd "C:\Users\MohammadSerhan\Desktop\Kar1Fitness"
git push -u origin master
```

### Step 3: Enter correct credentials when prompted
- **Username:** MohammadSerhan
- **Password:** [Your Personal Access Token for MohammadSerhan account]

**Note:** You need a Personal Access Token, not your GitHub password!
- Create one at: https://github.com/settings/tokens
- Select scope: "repo"

---

## Solution 2: Use Git Credential Manager

Run in Git Bash:
```bash
# Remove cached credentials for this repository
cd "C:\Users\MohammadSerhan\Desktop\Kar1Fitness"
git credential reject <<EOF
protocol=https
host=github.com
EOF

# Try push again
git push -u origin master
```

---

## Solution 3: Embed Username in Remote URL

This forces Git to use the specific username:

```bash
cd "C:\Users\MohammadSerhan\Desktop\Kar1Fitness"

# Remove current remote
git remote remove origin

# Add remote with username embedded
git remote add origin https://MohammadSerhan@github.com/MohammadSerhan/Kar1Fitness.git

# Push
git push -u origin master
```

When prompted, enter your Personal Access Token as the password.

---

## Solution 4: Use SSH Instead of HTTPS (Best Long-term Solution)

### Step 1: Generate SSH key (if you don't have one)
```bash
ssh-keygen -t ed25519 -C "ser7an.m@gmail.com"
# Press Enter for default location
# Optionally set a passphrase
```

### Step 2: Copy your public key
```bash
cat ~/.ssh/id_ed25519.pub
# Copy the output
```

### Step 3: Add SSH key to GitHub
1. Go to: https://github.com/settings/keys
2. Click "New SSH key"
3. Title: "Dev Machine"
4. Paste your public key
5. Click "Add SSH key"

### Step 4: Change remote to SSH
```bash
cd "C:\Users\MohammadSerhan\Desktop\Kar1Fitness"

# Remove HTTPS remote
git remote remove origin

# Add SSH remote
git remote add origin git@github.com:MohammadSerhan/Kar1Fitness.git

# Push
git push -u origin master
```

---

## Quick Command Reference

### Check which credentials are being used:
```bash
git config --list | grep credential
```

### Check current remote:
```bash
git remote -v
```

### Test GitHub connection:
```bash
ssh -T git@github.com
```

---

## After Fixing

Once you successfully push, you should see:
```
Enumerating objects: 73, done.
Counting objects: 100% (73/73), done.
...
To https://github.com/MohammadSerhan/Kar1Fitness.git
 * [new branch]      master -> master
```

Then visit: https://github.com/MohammadSerhan/Kar1Fitness
