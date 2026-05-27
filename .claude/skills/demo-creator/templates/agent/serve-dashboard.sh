#!/bin/bash
# Start HTTP server for dashboard
# Dashboard requires a server to load CSV files via fetch()

# Pick random port if not specified
PORT="${1:-$((8000 + RANDOM % 1000))}"

echo "========================================="
echo "Starting Dashboard Server"
echo "========================================="
echo ""
echo "Dashboard URL: http://localhost:$PORT/dashboard.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "========================================="
echo ""

# Try python3 first, then python
if command -v python3 &> /dev/null; then
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    python -m http.server "$PORT"
else
    echo "Error: Python not found. Please install Python to use the dashboard."
    exit 1
fi
