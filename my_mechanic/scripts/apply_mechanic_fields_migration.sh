#!/bin/bash

# Script to apply the mechanic fields migration to Supabase
# This adds the missing columns needed for shop editing functionality

echo "================================================"
echo "Applying Mechanic Fields Migration"
echo "================================================"
echo ""
echo "This migration will add the following columns to the mechanics table:"
echo "  - business_phone (TEXT)"
echo "  - latitude (DOUBLE PRECISION)"
echo "  - longitude (DOUBLE PRECISION)"
echo "  - is_accepting_clients (BOOLEAN)"
echo "  - average_rating (DECIMAL 3,2)"
echo "  - total_reviews (INTEGER)"
echo ""
echo "================================================"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI not found!"
    echo "Please install it first: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if we're in a Supabase project
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Error: Not in a Supabase project directory!"
    echo "Please run this from your project root."
    exit 1
fi

echo "📋 Migration file: supabase/migrations/20251106_add_mechanic_fields.sql"
echo ""
read -p "Do you want to apply this migration? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Applying migration..."
    echo ""
    
    # Apply the migration
    supabase db push
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Migration applied successfully!"
        echo ""
        echo "Your mechanics table now has all the required columns for shop editing."
    else
        echo ""
        echo "❌ Migration failed! Please check the error messages above."
        exit 1
    fi
else
    echo ""
    echo "Migration cancelled."
    exit 0
fi
