#!/usr/bin/env bash
# Quick verification script to check if everything is set up correctly

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        AWS Gitpod Environment Verification                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check AWS CLI installation
echo "1️⃣  Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    echo "   ✅ AWS CLI is installed"
    aws --version
else
    echo "   ❌ AWS CLI is NOT installed"
    exit 1
fi
echo ""

# Check AWS credentials
echo "2️⃣  Checking AWS credentials..."
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "   ✅ AWS environment variables are set"
else
    echo "   ⚠️  AWS environment variables are NOT set"
    echo "   Please configure them in Gitpod: https://gitpod.io/user/variables"
fi
echo ""

# Verify AWS access
echo "3️⃣  Verifying AWS access..."
if aws sts get-caller-identity &> /dev/null; then
    echo "   ✅ AWS credentials are valid!"
    aws sts get-caller-identity
else
    echo "   ❌ Cannot verify AWS credentials"
    echo "   Please check your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
fi
echo ""

# Check bash scripts
echo "4️⃣  Checking bash scripts..."
SCRIPTS_DIR="SAP_CO2/S2/bash-scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    echo "   ✅ Scripts directory found"
    SCRIPT_COUNT=$(find "$SCRIPTS_DIR" -type f | wc -l)
    echo "   Found $SCRIPT_COUNT scripts:"
    ls -1 "$SCRIPTS_DIR" | sed 's/^/      • /'
    
    # Check if scripts are executable
    echo ""
    echo "   Checking execute permissions..."
    NON_EXECUTABLE=$(find "$SCRIPTS_DIR" -type f ! -perm -u+x | wc -l)
    if [ "$NON_EXECUTABLE" -eq 0 ]; then
        echo "   ✅ All scripts are executable"
    else
        echo "   ⚠️  Some scripts are not executable. Making them executable..."
        chmod +x "$SCRIPTS_DIR"/*
        echo "   ✅ Fixed!"
    fi
else
    echo "   ❌ Scripts directory not found"
fi
echo ""

# Check test files
echo "5️⃣  Checking test files..."
TEST_DIR="temp/s3_bash"
if [ -d "$TEST_DIR" ]; then
    FILE_COUNT=$(find "$TEST_DIR" -type f -name "*.txt" | wc -l)
    echo "   ✅ Test files directory found"
    echo "   Found $FILE_COUNT test files"
else
    echo "   ⚠️  Test files directory not found"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo ""

# Final status
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    echo "🎉 All checks passed! You're ready to use AWS in Gitpod!"
    echo ""
    echo "📝 Quick start:"
    echo "   cd SAP_CO2/S2/bash-scripts"
    echo "   ./list-buckets"
else
    echo "⚠️  Some checks failed. Please review the output above."
    echo ""
    echo "💡 Need help? Check GITPOD_SETUP.md for detailed instructions."
fi
echo ""

