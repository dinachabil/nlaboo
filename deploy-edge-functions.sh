#!/bin/bash

# Supabase Edge Functions Deployment Script
# This script deploys all Edge Functions to Supabase

set -e  # Exit on any error

echo "🚀 Deploying Supabase Edge Functions..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Check if we're logged in to Supabase
if ! supabase projects list &> /dev/null; then
    echo "❌ Not logged in to Supabase. Please run:"
    echo "supabase login"
    exit 1
fi

# Navigate to supabase directory
cd supabase

# Deploy functions
echo "📦 Deploying Edge Functions..."

# Deploy create-match function
echo "  → Deploying create-match function..."
supabase functions deploy create-match

# Deploy create-team function
echo "  → Deploying create-team function..."
supabase functions deploy create-team

# Deploy get-matches function
echo "  → Deploying get-matches function..."
supabase functions deploy get-matches

echo "✅ All Edge Functions deployed successfully!"

# List deployed functions
echo ""
echo "📋 Deployed functions:"
supabase functions list

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "To test the functions, you can use:"
echo "curl -X POST 'https://gydwzgeojqydriamqfsj.supabase.co/functions/v1/create-match' \\"
echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"team1Id\": \"uuid\", \"team2Id\": \"uuid\", \"matchDate\": \"2024-01-01T10:00:00Z\", \"location\": \"Stadium\"}'"