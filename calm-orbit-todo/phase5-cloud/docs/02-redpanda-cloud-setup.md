# Redpanda Cloud Setup Guide

**Time Required**: 15-20 minutes
**Cost**: $0 (Free tier - 10GB storage, 10M messages/month)

---

## What is Redpanda Cloud?

Redpanda Cloud is a fully managed Kafka-compatible streaming platform. We're using it because:
- ✅ **Kafka-compatible**: Works with our existing Kafka code
- ✅ **Fully managed**: No need to manage Kafka servers
- ✅ **Free tier**: 10GB storage, 10M messages/month (enough for hackathon)
- ✅ **Cloud-native**: Perfect for DOKS deployment
- ✅ **Fast**: 10x faster than Apache Kafka

---

## Prerequisites

- Valid email address
- GitHub account (recommended for easier signup)
- Digital Ocean account (from previous guide)

---

## Step 1: Create Redpanda Cloud Account

### 1.1 Sign Up

1. **Go to Redpanda Cloud**
   - Open browser: https://redpanda.com/try-redpanda
   - Click **"Start Free"** or **"Sign Up"**

2. **Choose Sign Up Method**

   **Option A: GitHub (Recommended)**
   - Click **"Continue with GitHub"**
   - Authorize Redpanda to access your GitHub account
   - Faster verification

   **Option B: Email**
   - Enter your email address
   - Create a strong password
   - Click **"Sign Up"**
   - Check email for verification link
   - Click verification link

3. **Complete Profile**
   - First name and last name
   - Company name (optional - you can put "Personal Project" or "Hackathon")
   - Role: Select "Developer"
   - Use case: Select "Event Streaming" or "Microservices"

4. **Accept Terms**
   - Read and accept Terms of Service
   - Click **"Continue"**

---

## Step 2: Create Your First Cluster

### 2.1 Choose Cluster Type

After login, you'll see the cluster creation wizard:

1. **Cluster Name**
   - Enter: `hackathon-todo-cluster`
   - This name will be used in connection strings

2. **Cloud Provider**
   - Select: **"AWS"** (recommended for free tier)
   - Alternative: GCP or Azure (if you prefer)

3. **Region**
   - Select a region close to your Digital Ocean cluster
   - Recommended regions:
     - **US East (N. Virginia)** - `us-east-1` (if DOKS in NYC)
     - **US West (Oregon)** - `us-west-2` (if DOKS in SF)
     - **EU (Frankfurt)** - `eu-central-1` (if DOKS in EU)

   **Important**: Choose the same region or nearby region as your DOKS cluster for lower latency.

4. **Tier Selection**
   - Select: **"Serverless"** (Free tier)
   - This gives you:
     - 10 GB storage
     - 10M messages per month
     - 100 MB/s throughput
     - Perfect for hackathon!

5. **Review and Create**
   - Review your selections
   - Click **"Create Cluster"**
   - Wait 2-3 minutes for cluster provisioning

### 2.2 Wait for Cluster to be Ready

You'll see a progress indicator:
```
Creating cluster... ⏳
├─ Provisioning infrastructure
├─ Configuring networking
├─ Starting Redpanda brokers
└─ Cluster ready! ✅
```

When done, status will show: **"Running"** (green indicator)

---

## Step 3: Create Topics

Our application needs 4 Kafka topics for Phase 5 features.

### 3.1 Navigate to Topics

1. Click on your cluster: `hackathon-todo-cluster`
2. Click **"Topics"** tab (left sidebar)
3. Click **"Create Topic"** button

### 3.2 Create Topic 1: task-events

1. **Topic Name**: `task-events`
2. **Partitions**: `3`
3. **Replication Factor**: `3` (default, managed by Redpanda)
4. **Retention**: `7 days` (default)
5. **Cleanup Policy**: `delete` (default)
6. Click **"Create"**

### 3.3 Create Topic 2: recurring-task-events

1. **Topic Name**: `recurring-task-events`
2. **Partitions**: `3`
3. **Replication Factor**: `3`
4. **Retention**: `7 days`
5. **Cleanup Policy**: `delete`
6. Click **"Create"**

### 3.4 Create Topic 3: reminder-events

1. **Topic Name**: `reminder-events`
2. **Partitions**: `3`
3. **Replication Factor**: `3`
4. **Retention**: `7 days`
5. **Cleanup Policy**: `delete`
6. Click **"Create"**

### 3.5 Create Topic 4: notification-events

1. **Topic Name**: `notification-events`
2. **Partitions**: `3`
3. **Replication Factor**: `3`
4. **Retention**: `7 days`
5. **Cleanup Policy**: `delete`
6. Click **"Create"**

### 3.6 Verify All Topics Created

You should now see 4 topics in the Topics list:
```
✅ task-events (3 partitions)
✅ recurring-task-events (3 partitions)
✅ reminder-events (3 partitions)
✅ notification-events (3 partitions)
```

---

## Step 4: Create Service Account (Authentication)

We need credentials to connect our application to Redpanda Cloud.

### 4.1 Navigate to Security

1. Click **"Security"** tab (left sidebar)
2. Click **"Service Accounts"**
3. Click **"Create Service Account"**

### 4.2 Create Service Account

1. **Name**: `todo-app-service-account`
2. **Description**: `Service account for Todo App backend`
3. Click **"Create"**

### 4.3 Generate API Key

1. After creating service account, click on it
2. Click **"Create API Key"**
3. **Key Name**: `todo-app-api-key`
4. Click **"Create"**

### 4.4 Save Credentials (IMPORTANT!)

⚠️ **CRITICAL**: These credentials are shown only once!

You'll see:
```
API Key: rp_abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
API Secret: abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789
```

**Save these immediately**:
1. Copy API Key to a text file
2. Copy API Secret to the same text file
3. Save file as: `redpanda-credentials.txt`
4. Keep this file safe (don't commit to GitHub!)

---

## Step 5: Get Connection Details

### 5.1 Get Bootstrap Servers

1. Go to **"Overview"** tab
2. Look for **"Bootstrap Servers"** section
3. Copy the connection string

It will look like:
```
seed-abc123.xyz.cloud.redpanda.com:9092
```

Save this as well in your `redpanda-credentials.txt` file.

### 5.2 Complete Credentials File

Your `redpanda-credentials.txt` should now have:

```
REDPANDA CLOUD CREDENTIALS
==========================

Cluster Name: hackathon-todo-cluster
Bootstrap Servers: seed-abc123.xyz.cloud.redpanda.com:9092

API Key: rp_abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
API Secret: abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789

Topics Created:
- task-events
- recurring-task-events
- reminder-events
- notification-events
```

---

## Step 6: Grant Permissions to Service Account

### 6.1 Navigate to ACLs (Access Control Lists)

1. Click **"Security"** tab
2. Click **"ACLs"**
3. Click **"Create ACL"**

### 6.2 Create ACL for All Topics

We need to give our service account permission to read/write to all topics.

**ACL 1: Allow WRITE to all topics**
1. **Principal**: Select `todo-app-service-account`
2. **Resource Type**: `Topic`
3. **Resource Name**: `*` (all topics)
4. **Pattern Type**: `Literal`
5. **Operation**: `Write`
6. **Permission**: `Allow`
7. Click **"Create"**

**ACL 2: Allow READ to all topics**
1. **Principal**: Select `todo-app-service-account`
2. **Resource Type**: `Topic`
3. **Resource Name**: `*`
4. **Pattern Type**: `Literal`
5. **Operation**: `Read`
6. **Permission**: `Allow`
7. Click **"Create"**

**ACL 3: Allow CREATE topics (for auto-creation)**
1. **Principal**: Select `todo-app-service-account`
2. **Resource Type**: `Topic`
3. **Resource Name**: `*`
4. **Pattern Type**: `Literal`
5. **Operation**: `Create`
6. **Permission**: `Allow`
7. Click **"Create"**

**ACL 4: Allow DESCRIBE topics**
1. **Principal**: Select `todo-app-service-account`
2. **Resource Type**: `Topic`
3. **Resource Name**: `*`
4. **Pattern Type**: `Literal`
5. **Operation**: `Describe`
6. **Permission**: `Allow`
7. Click **"Create"**

**ACL 5: Allow consumer group operations**
1. **Principal**: Select `todo-app-service-account`
2. **Resource Type**: `Group`
3. **Resource Name**: `*`
4. **Pattern Type**: `Literal`
5. **Operation**: `Read`
6. **Permission**: `Allow`
7. Click **"Create"**

### 6.3 Verify ACLs

You should now see 5 ACLs in the list:
```
✅ todo-app-service-account | Topic | * | Write | Allow
✅ todo-app-service-account | Topic | * | Read | Allow
✅ todo-app-service-account | Topic | * | Create | Allow
✅ todo-app-service-account | Topic | * | Describe | Allow
✅ todo-app-service-account | Group | * | Read | Allow
```

---

## Step 7: Test Connection (Optional but Recommended)

Let's verify we can connect to Redpanda Cloud from your local machine.

### 7.1 Install rpk (Redpanda CLI)

**For Windows (WSL2/Ubuntu):**
```bash
# Download rpk
curl -LO https://github.com/redpanda-data/redpanda/releases/latest/download/rpk-linux-amd64.zip

# Extract
unzip rpk-linux-amd64.zip

# Move to PATH
sudo mv rpk /usr/local/bin/

# Verify
rpk version
```

**For macOS:**
```bash
# Using Homebrew
brew install redpanda-data/tap/redpanda

# Verify
rpk version
```

### 7.2 Configure rpk

Create a configuration file:

```bash
# Create config directory
mkdir -p ~/.config/rpk

# Create profile
cat > ~/.config/rpk/profile.yaml << 'EOF'
name: redpanda-cloud
kafka_api:
  brokers:
    - seed-abc123.xyz.cloud.redpanda.com:9092
  sasl:
    mechanism: SCRAM-SHA-256
    user: rp_abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
    password: abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789
  tls:
    enabled: true
EOF
```

**Replace**:
- `seed-abc123.xyz.cloud.redpanda.com:9092` with your Bootstrap Servers
- `rp_abc123...` with your API Key
- `abcdefgh...` with your API Secret

### 7.3 Test Connection

```bash
# List topics
rpk topic list

# Expected output:
# NAME                    PARTITIONS  REPLICAS
# task-events             3           3
# recurring-task-events   3           3
# reminder-events         3           3
# notification-events     3           3
```

If you see the topics, connection is working! ✅

### 7.4 Test Produce/Consume (Optional)

```bash
# Produce a test message
echo "test message" | rpk topic produce task-events

# Consume the message
rpk topic consume task-events --num 1
```

If you see your message, everything is working perfectly! ✅

---

## Step 8: Prepare Environment Variables for Backend

We need to update our backend configuration to use Redpanda Cloud instead of local Kafka.

### 8.1 Create Kubernetes Secret Configuration

Create a file: `redpanda-cloud-config.txt`

```bash
# Redpanda Cloud Configuration for Kubernetes
KAFKA_BOOTSTRAP_SERVERS=seed-abc123.xyz.cloud.redpanda.com:9092
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=SCRAM-SHA-256
KAFKA_SASL_USERNAME=rp_abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
KAFKA_SASL_PASSWORD=abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789
```

**Replace** with your actual values from Step 5.2.

**Important**: Keep this file safe! We'll use it when deploying to DOKS.

---

## Troubleshooting

### Issue 1: "Cluster creation failed"

**Solution**:
- Check if you've exceeded free tier limits (1 cluster max)
- Try a different region
- Contact Redpanda support: https://redpanda.com/support

### Issue 2: "Authentication failed" when testing

**Solution**:
- Verify API Key and Secret are correct (no extra spaces)
- Check if service account has proper ACLs
- Ensure SASL mechanism is `SCRAM-SHA-256`

### Issue 3: "Topic not found"

**Solution**:
- Verify topic name spelling (case-sensitive)
- Check if topics were created successfully
- Wait 1-2 minutes for topic propagation

### Issue 4: "Permission denied" errors

**Solution**:
- Check ACLs are created for the service account
- Verify all 5 ACLs exist (Write, Read, Create, Describe, Group)
- Try recreating the service account

### Issue 5: "Connection timeout"

**Solution**:
- Check if bootstrap servers URL is correct
- Verify TLS is enabled (`tls: enabled: true`)
- Check firewall/network settings
- Try from a different network

---

## Cost Breakdown

### Free Tier Limits:
- **Storage**: 10 GB
- **Messages**: 10M per month
- **Throughput**: 100 MB/s
- **Retention**: 7 days

### Our Expected Usage (Hackathon):
- **Messages**: ~100K per month (well under limit)
- **Storage**: ~500 MB (well under limit)
- **Cost**: **$0** (completely free)

### After Free Tier:
If you exceed limits, pricing starts at:
- **Storage**: $0.10 per GB per month
- **Messages**: $0.50 per million messages
- **Estimated cost for small app**: $5-10 per month

---

## Security Best Practices

1. **Never Commit Credentials to GitHub**
   - Add `redpanda-credentials.txt` to `.gitignore`
   - Use Kubernetes Secrets for production

2. **Use Service Accounts, Not User Accounts**
   - Service accounts are designed for applications
   - Easier to rotate credentials

3. **Principle of Least Privilege**
   - Only grant necessary permissions
   - Use specific topic names instead of `*` in production

4. **Rotate Credentials Regularly**
   - Create new API keys every 90 days
   - Delete old keys after rotation

5. **Monitor Usage**
   - Check Redpanda Cloud dashboard weekly
   - Set up alerts for unusual activity

---

## Next Steps

✅ **You've completed Redpanda Cloud setup!**

**What we have now**:
- ✅ Redpanda Cloud cluster running
- ✅ 4 topics created (task-events, recurring-task-events, reminder-events, notification-events)
- ✅ Service account with proper permissions
- ✅ Connection credentials saved
- ✅ Configuration ready for DOKS deployment

**Next Guide**: `03-doks-cluster-deployment.md`
- Create Kubernetes cluster on Digital Ocean
- Configure kubectl
- Deploy our application

---

## Quick Reference

### Important URLs:
- Dashboard: https://cloud.redpanda.com/
- Documentation: https://docs.redpanda.com/
- Support: https://redpanda.com/support

### Important Information:
```
Cluster Name: hackathon-todo-cluster
Bootstrap Servers: seed-abc123.xyz.cloud.redpanda.com:9092
API Key: rp_abc123... (saved in redpanda-credentials.txt)
API Secret: abcdefgh... (saved in redpanda-credentials.txt)

Topics:
- task-events (3 partitions)
- recurring-task-events (3 partitions)
- reminder-events (3 partitions)
- notification-events (3 partitions)
```

### Test Commands:
```bash
# List topics
rpk topic list

# Produce test message
echo "test" | rpk topic produce task-events

# Consume messages
rpk topic consume task-events --num 1

# Check cluster info
rpk cluster info
```

---

**Status**: ✅ Ready for next step
**Time Taken**: ~15-20 minutes
**Cost So Far**: $0 (using free tier)
