#!/bin/bash

# Start nginx in the background
nginx -g "daemon off;" &

# Start cadvisor with correct flags
# Note: cAdvisor v0.53.0 uses -listen_ip and -port instead of -listen_address
/usr/local/bin/cadvisor \
    -listen_ip="127.0.0.1" \
    -port=8080 \
    -housekeeping_interval=10s \
    -max_housekeeping_interval=15s \
    -storage_duration=1m0s \
    &

# Wait for both processes
wait
