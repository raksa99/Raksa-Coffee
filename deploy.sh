#!/bin/bash

# Exit immediately if any command fails
set -e

echo "=== 1. Building Flutter Web Application ==="
flutter build web --release

echo ""
echo "=== 2. Deploying to Vercel (raksa-coffee) ==="
npx vercel deploy build/web --prod --yes

echo ""
echo "=== Deployment Completed Successfully! ==="
echo "Your live POS app is updated at: https://raksa-coffee.vercel.app"
