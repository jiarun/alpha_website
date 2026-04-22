#!/bin/bash
# Deploy static website to AWS S3
# Usage: ./deploy.sh <your-bucket-name>

BUCKET=${1:-"smashkids-website"}
REGION="us-east-1"
WEBSITE_DIR="./website"

echo "🏸 Deploying SmashKids website to S3..."

# 1. Create bucket
aws s3 mb s3://$BUCKET --region $REGION

# 2. Disable block public access
aws s3api put-public-access-block \
  --bucket $BUCKET \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# 3. Set bucket policy for public read
aws s3api put-bucket-policy --bucket $BUCKET --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"PublicReadGetObject\",
    \"Effect\": \"Allow\",
    \"Principal\": \"*\",
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::$BUCKET/*\"
  }]
}"

# 4. Enable static website hosting
aws s3 website s3://$BUCKET \
  --index-document index.html \
  --error-document index.html

# 5. Upload files
aws s3 sync $WEBSITE_DIR s3://$BUCKET --delete

echo ""
echo "✅ Deployed! Your website is live at:"
echo "   http://$BUCKET.s3-website-$REGION.amazonaws.com"
