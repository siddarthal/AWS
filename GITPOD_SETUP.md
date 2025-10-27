# 🚀 Gitpod Setup Guide for AWS Development

This guide will help you set up and use Gitpod for developing and testing your AWS bash scripts online.

## 📋 Prerequisites

1. A GitHub/GitLab/Bitbucket account with this repository
2. A [Gitpod account](https://gitpod.io) (free tier available)
3. AWS credentials (Access Key ID and Secret Access Key)

## 🔧 Initial Setup

### Step 1: Connect Your Repository to Gitpod

You can open your repository in Gitpod in several ways:

**Option A: Using Browser Extension**
1. Install the [Gitpod browser extension](https://www.gitpod.io/docs/browser-extension)
2. Navigate to your GitHub/GitLab repository
3. Click the "Gitpod" button that appears

**Option B: Using URL Prefix**
```
https://gitpod.io/#https://github.com/YOUR_USERNAME/YOUR_REPO
```

**Option C: Using Gitpod Dashboard**
1. Go to [gitpod.io](https://gitpod.io)
2. Click "New Workspace"
3. Enter your repository URL

### Step 2: Configure AWS Credentials (IMPORTANT!)

For security and persistence, configure AWS credentials as environment variables:

1. Go to [Gitpod User Variables](https://gitpod.io/user/variables)
2. Click "New Variable"
3. Add the following variables:

| Name | Value | Scope |
|------|-------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key | `your-repo-url/*` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key | `your-repo-url/*` |
| `AWS_DEFAULT_REGION` | `ap-south-2` (or your region) | `your-repo-url/*` |

**Scope Example:** If your repo is `github.com/username/aws-scripts`, use scope: `username/aws-scripts/*`

> ⚠️ **Security Note**: Never commit AWS credentials to your repository! Use Gitpod environment variables.

### Step 3: Start Your Workspace

Once you open your workspace in Gitpod:
1. The `.gitpod.yml` configuration will automatically:
   - Install the latest AWS CLI
   - Make all bash scripts executable
   - Display helpful information
2. Wait for the setup to complete (usually 1-2 minutes on first launch)

## 🎯 Using Your AWS Scripts

### Navigate to Scripts Directory
```bash
cd SAP_CO2/S2/bash-scripts
```

### Available Scripts

1. **List Buckets**
   ```bash
   ./list-buckets
   ```

2. **Create Bucket**
   ```bash
   ./create-bucket my-unique-bucket-name-12345
   ```

3. **Put Objects**
   ```bash
   ./put-objects bucket-name file-path
   ```

4. **List Objects**
   ```bash
   ./list-objects bucket-name
   ```

5. **Delete Bucket**
   ```bash
   ./delete-bucket bucket-name
   ```

6. **Sync Files**
   ```bash
   ./sync source-path s3://bucket-name/prefix
   ```

7. **Get Newest Buckets**
   ```bash
   ./get-newest-buckets
   ```

## 🔍 Verify AWS Configuration

Check if AWS credentials are properly configured:
```bash
aws sts get-caller-identity
```

This should display your AWS account information.

## 💡 Tips & Best Practices

### 1. Testing with Temporary Buckets
Create unique bucket names using timestamps:
```bash
./create-bucket test-bucket-$(date +%s)
```

### 2. Quick AWS CLI Commands
```bash
# List all S3 buckets
aws s3 ls

# Check AWS configuration
aws configure list

# Test S3 access
aws s3api list-buckets
```

### 3. Using the Test Files
Your repository includes test files in `temp/s3_bash/`. You can use these for testing uploads:
```bash
cd /workspace/AWS
./SAP_CO2/S2/bash-scripts/put-objects your-bucket-name temp/s3_bash/textFile1.txt
```

### 4. Debugging Scripts
Add `set -x` to your bash scripts to see detailed execution:
```bash
#!/usr/bin/env bash
set -x  # Enable debug mode
set -e  # Exit on error
```

## 🛠️ Troubleshooting

### Issue: AWS credentials not found
**Solution:**
- Ensure environment variables are set in Gitpod settings
- Restart the workspace after adding variables
- Temporarily set credentials in terminal:
  ```bash
  export AWS_ACCESS_KEY_ID=your_key
  export AWS_SECRET_ACCESS_KEY=your_secret
  export AWS_DEFAULT_REGION=ap-south-2
  ```

### Issue: Permission denied when running scripts
**Solution:**
```bash
chmod +x SAP_CO2/S2/bash-scripts/*
```

### Issue: Bucket already exists error
**Solution:**
- S3 bucket names must be globally unique
- Add a unique suffix: `my-bucket-$(date +%s)`
- Or use your AWS account ID: `my-bucket-123456789012`

### Issue: Region errors
**Solution:**
Your scripts use `ap-south-2` region. Ensure:
- This region is enabled in your AWS account
- You have the correct credentials for this region
- Or modify the scripts to use a different region

## 📚 Additional Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Gitpod Documentation](https://www.gitpod.io/docs)
- [AWS S3 API Reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/)
- [Gitpod Environment Variables](https://www.gitpod.io/docs/environment-variables)

## 🎨 VS Code Extensions Included

The workspace automatically installs:
- **ShellCheck**: Linting for bash scripts
- **Shell Format**: Auto-formatting for scripts
- **AWS Toolkit**: AWS resource explorer and tools
- **YAML**: Better YAML editing support

## 📝 Example Workflow

Here's a complete example workflow:

```bash
# 1. Navigate to scripts
cd SAP_CO2/S2/bash-scripts

# 2. Verify AWS access
aws sts get-caller-identity

# 3. List existing buckets
./list-buckets

# 4. Create a new test bucket
BUCKET_NAME="test-bucket-$(date +%s)"
./create-bucket $BUCKET_NAME

# 5. Upload a test file
cd /workspace/AWS
./SAP_CO2/S2/bash-scripts/put-objects $BUCKET_NAME temp/s3_bash/textFile1.txt

# 6. List objects in bucket
./SAP_CO2/S2/bash-scripts/list-objects $BUCKET_NAME

# 7. Clean up - delete bucket
./SAP_CO2/S2/bash-scripts/delete-bucket $BUCKET_NAME
```

## 🔒 Security Reminders

- ✅ Always use Gitpod environment variables for credentials
- ✅ Never commit `.aws/` directory
- ✅ Never hardcode credentials in scripts
- ✅ Use IAM roles with minimal required permissions
- ✅ Regularly rotate your AWS access keys
- ✅ Delete test buckets after use to avoid charges

---

**Happy Coding! 🎉**

If you encounter any issues, check the troubleshooting section or refer to the AWS/Gitpod documentation.

