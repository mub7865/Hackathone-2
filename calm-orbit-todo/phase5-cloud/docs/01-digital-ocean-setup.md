# Digital Ocean Account Setup Guide

**Time Required**: 15-20 minutes
**Cost**: $0 (Free $200 credit for 60 days)

---

## Prerequisites

- Valid email address
- Credit/Debit card (for verification only - won't be charged)
- GitHub account (optional, for easier signup)

---

## Step 1: Create Digital Ocean Account

### Option A: Sign Up with GitHub (Recommended - Faster)

1. **Go to Digital Ocean**
   - Open browser: https://www.digitalocean.com/
   - Click **"Sign Up"** button (top right)

2. **Choose GitHub Sign Up**
   - Click **"Sign up with GitHub"**
   - Authorize Digital Ocean to access your GitHub account
   - This automatically verifies your identity

3. **Complete Profile**
   - Enter your name
   - Choose password (if not using GitHub)
   - Accept Terms of Service

### Option B: Sign Up with Email

1. **Go to Digital Ocean**
   - Open browser: https://www.digitalocean.com/
   - Click **"Sign Up"** button

2. **Enter Details**
   - Email address
   - Password (strong password required)
   - Click **"Sign Up"**

3. **Verify Email**
   - Check your email inbox
   - Click verification link in email from Digital Ocean
   - This may take 1-2 minutes

---

## Step 2: Activate $200 Free Credit

### Important Notes:
- ✅ Free $200 credit valid for 60 days
- ✅ No charges during free period
- ✅ Credit card required for verification only
- ⚠️ After 60 days or $200 used, billing starts (you can cancel anytime)

### Steps:

1. **After Login, Look for Promo Banner**
   - You'll see: "Get $200 in credit over 60 days"
   - Click **"Claim Your Credit"** or **"Get Started"**

2. **If No Banner Visible**
   - Go to: https://try.digitalocean.com/freetrialoffer/
   - Or search "Digital Ocean $200 credit" in Google
   - Click the promotional link

3. **Enter Billing Information**
   - Click **"Add Payment Method"**
   - Choose: Credit Card or PayPal

   **For Credit Card:**
   - Card number
   - Expiry date
   - CVV
   - Billing address

   **Important**: This is for verification only. You won't be charged during the 60-day trial.

4. **Verify Your Account**
   - Digital Ocean may send a small verification charge ($1-2)
   - This will be refunded immediately
   - Check your card statement to confirm

5. **Confirm Credit Applied**
   - After verification, go to **"Billing"** section (left sidebar)
   - You should see: **"$200.00 credit remaining"**
   - Expiry date: 60 days from today

---

## Step 3: Complete Account Setup

### 3.1 Tell Us About Your Project (Survey)

Digital Ocean will ask a few questions:
- **What will you use Digital Ocean for?**
  - Select: "Deploy a web application"
- **What's your role?**
  - Select: "Developer" or "Student"
- **Team size?**
  - Select: "Just me"

Click **"Continue"** or **"Skip"** (optional survey)

### 3.2 Enable Two-Factor Authentication (Recommended)

1. Go to **"Settings"** → **"Security"**
2. Click **"Enable Two-Factor Authentication"**
3. Use Google Authenticator or Authy app
4. Scan QR code
5. Enter 6-digit code to verify

---

## Step 4: Install Digital Ocean CLI (doctl)

The `doctl` command-line tool lets you manage Digital Ocean from terminal.

### For Windows (WSL2/Ubuntu):

```bash
# Download latest version
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz

# Extract
tar xf doctl-1.104.0-linux-amd64.tar.gz

# Move to PATH
sudo mv doctl /usr/local/bin

# Verify installation
doctl version
```

Expected output:
```
doctl version 1.104.0-release
```

### For macOS:

```bash
# Using Homebrew
brew install doctl

# Verify
doctl version
```

### For Linux:

```bash
# Using snap
sudo snap install doctl

# Verify
doctl version
```

---

## Step 5: Authenticate doctl with Your Account

### 5.1 Create API Token

1. **Go to Digital Ocean Dashboard**
   - Click your profile icon (top right)
   - Select **"API"**

2. **Generate New Token**
   - Click **"Generate New Token"**
   - Token name: `hackathon-deployment`
   - Scopes: Select **"Read & Write"** (both checkboxes)
   - Click **"Generate Token"**

3. **Copy Token Immediately**
   - ⚠️ **IMPORTANT**: Token is shown only once!
   - Copy the long string (starts with `dop_v1_...`)
   - Save it somewhere safe (you'll need it in next step)

### 5.2 Authenticate doctl

```bash
# Initialize authentication
doctl auth init

# When prompted, paste your API token
# Press Enter
```

Expected output:
```
Please authenticate doctl for use with your DigitalOcean account. You can generate a token in the control panel at https://cloud.digitalocean.com/account/api/tokens

Enter your access token: [paste token here]

Validating token... OK
```

### 5.3 Verify Authentication

```bash
# Test connection
doctl account get
```

Expected output (your details):
```
Email                    Droplet Limit    Email Verified    UUID                                    Status
your-email@example.com   10               true              abc123-def456-ghi789-jkl012-mno345      active
```

---

## Step 6: Verify Everything is Ready

Run these commands to confirm setup:

```bash
# 1. Check doctl version
doctl version

# 2. Check authentication
doctl account get

# 3. Check available regions
doctl compute region list

# 4. Check Kubernetes versions available
doctl kubernetes options versions
```

If all commands work, you're ready! ✅

---

## Troubleshooting

### Issue 1: "doctl: command not found"

**Solution**:
```bash
# Check if doctl is in PATH
which doctl

# If not found, add to PATH
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue 2: "Unable to authenticate you"

**Solution**:
- Token may be incorrect or expired
- Generate a new token (Step 5.1)
- Run `doctl auth init` again with new token

### Issue 3: "Credit card verification failed"

**Solution**:
- Try a different card
- Contact Digital Ocean support: https://www.digitalocean.com/support
- Use PayPal instead of credit card

### Issue 4: "$200 credit not showing"

**Solution**:
- Wait 5-10 minutes after verification
- Refresh the Billing page
- Check email for confirmation
- If still not showing, contact support with promo code: **DOKS200**

---

## Cost Breakdown (For Your Reference)

### What We'll Use:

| Resource | Cost per Hour | Cost per Month | Our Usage | Total Cost |
|----------|---------------|----------------|-----------|------------|
| DOKS Cluster (2 nodes, 2GB RAM each) | $0.03/hr | $24/month | ~1 month | ~$24 |
| Load Balancer | $0.015/hr | $12/month | ~1 month | ~$12 |
| Container Registry | Free | Free (500MB) | Free | $0 |
| **TOTAL** | | | | **~$36/month** |

### Your Free Credit:
- You have: **$200 credit**
- We'll use: **~$36 for 1 month**
- Remaining: **$164** (enough for 4+ more months)

---

## Security Best Practices

1. **Never Share Your API Token**
   - Treat it like a password
   - Don't commit to GitHub
   - Don't share in screenshots

2. **Enable 2FA**
   - Protects your account from unauthorized access

3. **Use Read-Only Tokens When Possible**
   - For monitoring/viewing only
   - Use Read & Write only for deployment

4. **Regularly Rotate Tokens**
   - Delete old tokens you're not using
   - Create new tokens every few months

5. **Monitor Your Billing**
   - Check billing dashboard weekly
   - Set up billing alerts (Settings → Billing → Alerts)
   - Recommended: Alert at $50, $100, $150

---

## Next Steps

✅ **You've completed Digital Ocean setup!**

**Next Guide**: `02-redpanda-cloud-setup.md`
- Set up Kafka cluster in the cloud
- Get connection credentials
- Configure event streaming

---

## Quick Reference

### Important URLs:
- Dashboard: https://cloud.digitalocean.com/
- API Tokens: https://cloud.digitalocean.com/account/api/tokens
- Billing: https://cloud.digitalocean.com/billing
- Support: https://www.digitalocean.com/support

### Important Commands:
```bash
# Check account
doctl account get

# List regions
doctl compute region list

# List Kubernetes versions
doctl kubernetes options versions

# Check billing
doctl balance get
```

---

**Status**: ✅ Ready for next step
**Time Taken**: ~15-20 minutes
**Cost So Far**: $0 (using free credit)
