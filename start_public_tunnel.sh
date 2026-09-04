#!/bin/bash
echo "============================================================"
echo "🌐 Starting Public Internet Tunnel for ShiftOps Backend"
echo "============================================================"
echo "This exposes your backend (port 5050) to ANY mobile network (4G/5G/Wi-Fi) worldwide."
echo ""

# Try localtunnel
npx -y localtunnel --port 5050
