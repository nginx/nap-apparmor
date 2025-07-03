#!/bin/bash

set -eE -x

#Start time
start_time=$(date +%H:%M)

#Define log path
apparmor_log_file="apparmor_denial_logs"

#Error handler
on_error() {
    set +x 
    echo ""
    echo "A command failed. Checking for AppArmor denials since $start_time..."

    if command -v journalctl >/dev/null 2>&1; then 
        # Fetch all DENIED logs since script start
        log_output=$(sudo journalctl --since "$start_time" | grep "DENIED")
        if [ "$(echo "$log_output" | grep -c .)" -gt 0 ]; then
            echo "AppArmor denials detected:"
            echo "$log_output" | tee "$apparmor_log_file";
            set -x 
        else
            echo "No AppArmor denials found in journal logs."
        fi
    else
        echo "journalctl not found! Cannot check AppArmor denial logs."
    fi
    set -x
}
trap on_error ERR

#change dir
cd /etc/app_protect/

#Clear previous logs
sudo rm -rf $apparmor_log_file

#nginx configuration
echo "Testing NGINX configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "NGINX configuration test failed! Exiting."
    exit 1
fi
echo "NGINX configuration test passed."

#AppArmor profile check
echo "Checking AppArmor status..."
aa-status || true

#Systemctl
systemctl stop nginx
systemctl start nginx
systemctl restart nginx
systemctl status --no-pager nginx
systemctl stop nginx-app-protect
systemctl start nginx-app-protect
systemctl restart nginx-app-protect
systemctl status --no-pager nginx-app-protect


#Curl
curl localhost 
sleep 5
curl localhost 
curl "localhost/<script>"

echo "Script completed successfully. No AppArmor errors triggered."
