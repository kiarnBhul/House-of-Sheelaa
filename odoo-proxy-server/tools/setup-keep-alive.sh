#!/bin/bash

# Quick setup script for external keep-alive monitoring
# This script provides instructions and links to set up external monitoring

echo "=================================================="
echo "🚀 House of Sheelaa - Keep Server Awake 24/7"
echo "=================================================="
echo ""

# Get Render URL from user
echo "Enter your Render URL (e.g., https://my-proxy.onrender.com):"
read -r RENDER_URL

if [ -z "$RENDER_URL" ]; then
    echo "❌ Error: Render URL is required"
    exit 1
fi

# Remove trailing slash if present
RENDER_URL="${RENDER_URL%/}"

echo ""
echo "✅ Your Render URL: $RENDER_URL"
echo ""
echo "=================================================="
echo "📋 Setup External Keep-Alive (Choose ONE):"
echo "=================================================="
echo ""

echo "🔹 OPTION 1: Cron-Job.org (Easiest - No signup)"
echo "   1. Go to: https://cron-job.org/en/"
echo "   2. Click 'Create cronjob'"
echo "   3. Enter URL: ${RENDER_URL}/health"
echo "   4. Schedule: */5 * * * * (every 5 minutes)"
echo "   5. Click 'Create'"
echo ""

echo "🔹 OPTION 2: UptimeRobot.com (Free - 50 monitors)"
echo "   1. Sign up: https://uptimerobot.com"
echo "   2. Add New Monitor → HTTP(s)"
echo "   3. URL: ${RENDER_URL}/health"
echo "   4. Interval: 5 minutes"
echo "   5. Save"
echo ""

echo "🔹 OPTION 3: BetterUptime.com (Professional)"
echo "   1. Sign up: https://betterstack.com/better-uptime"
echo "   2. Create Monitor"
echo "   3. URL: ${RENDER_URL}/health"
echo "   4. Interval: 5 minutes"
echo "   5. Save"
echo ""

echo "=================================================="
echo "🧪 Test Your Server (Right Now!)"
echo "=================================================="
echo ""
echo "Testing health endpoint..."

# Test the health endpoint
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${RENDER_URL}/health" -m 10)
    
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ Server is AWAKE and responding!"
        echo ""
        echo "Full response:"
        curl -s "${RENDER_URL}/health" | python3 -m json.tool 2>/dev/null || curl -s "${RENDER_URL}/health"
    elif [ "$RESPONSE" = "000" ]; then
        echo "⏰ Server might be SLEEPING (this is normal on first access)"
        echo "   It will wake up in 30-60 seconds"
        echo "   Setting up external monitoring will prevent this!"
    else
        echo "⚠️ Server returned status: $RESPONSE"
        echo "   Check Render logs for errors"
    fi
else
    echo "ℹ️ curl not found - test manually:"
    echo "   Open browser: ${RENDER_URL}/health"
    echo "   Should show: {\"ok\": true, \"status\": \"healthy\"}"
fi

echo ""
echo "=================================================="
echo "✅ Next Steps:"
echo "=================================================="
echo ""
echo "1. ✅ Setup ONE of the external monitors above"
echo "2. ✅ Wait 5 minutes for first ping"
echo "3. ✅ Check Render logs to confirm pings working"
echo "4. ✅ Test Flutter app - should load instantly!"
echo ""
echo "📖 For detailed instructions, see:"
echo "   KEEP_ALIVE_SETUP.md"
echo ""
echo "🆘 Need help? Check Render logs and KEEP_ALIVE_SETUP.md"
echo "=================================================="
