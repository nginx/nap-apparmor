#!/bin/bash
set -euo pipefail  # Strict error handling

echo "[INFO] Starting NGINX App Protect AppArmor setup"

# 1. Verify AppArmor is running
if ! systemctl is-active --quiet apparmor; then
    echo "[ERROR] AppArmor is not running. Starting it now..."
    sudo systemctl start apparmor || { echo "[FAIL] Could not start AppArmor"; exit 1; }
fi

# 2. Check/install AppArmor-related and required packages
REQUIRED_PACKAGES=(
    apparmor
    apparmor-utils
    auditd
    curl
    systemd
    apt-transport-https
    lsb-release
    ca-certificates
    wget
    gnupg2 
    systemd 
    vim 
)

echo "[INFO] Installing required packages..."
sudo apt update && sudo apt install -y "${REQUIRED_PACKAGES[@]}" || {
    echo "[FAIL] Could not install required packages"
    exit 1
}

# Check if aa-complain is available after install
if ! command -v aa-complain >/dev/null 2>&1; then
    echo "[FAIL] apparmor-utils did not install correctly or aa-complain is not available"
    exit 1
fi

echo "[INFO] Copying AppArmor profiles to /etc/apparmor.d..."

# 3. Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="${SCRIPT_DIR}"


# Define source and destination mapping
declare -A PROFILE_MAP=(
    ["${POLICY_DIR}/usr.sbin.nginx"]="/etc/apparmor.d/usr.sbin.nginx"
    ["${POLICY_DIR}/usr.share.ts.bd-socket-plugin"]="/etc/apparmor.d/usr.share.ts.bd-socket-plugin"
)

# Loop to validate and copy each profile
for src in "${!PROFILE_MAP[@]}"; do
    dest="${PROFILE_MAP[$src]}"
    if [ -f "$src" ]; then
        sudo cp "$src" "$dest" || {
            echo "[FAIL] Failed to copy $src to $dest"
            exit 1
        }
    else
        echo "[ERROR] $src not found!"
        exit 1
    fi
done

# Check if profiles exist before reloading
declare -a PROFILES=(
    "/etc/apparmor.d/usr.sbin.nginx"
    "/etc/apparmor.d/usr.share.ts.bd-socket-plugin"
)

for profile in "${PROFILES[@]}"; do
    if [[ ! -f "$profile" ]]; then
        echo "[ERROR] Profile $profile not found!"
        exit 1
    fi
done

# 4. Reload AppArmor policies with validation
echo "[INFO] Reloading AppArmor policies..."
sudo apparmor_parser -r "${PROFILES[@]}" || { echo "[FAIL] Failed to reload profiles"; exit 1; }

# 5. Temporarily set complain mode for debugging
echo "[INFO] Setting complain mode for NGINX and bd-socket-plugin..."
sudo aa-complain /usr/sbin/nginx
sudo aa-complain /usr/share/ts/bin/bd-socket-plugin

# 6. Restart NGINX and verify it runs
echo "[INFO] Restarting NGINX..."
sudo systemctl restart nginx || { echo "[FAIL] NGINX restart failed"; exit 1; }

echo "[INFO] Checking NGINX status..."
sudo systemctl is-active --quiet nginx && echo "[INFO] NGINX is running" || { echo "[FAIL] NGINX is not running"; exit 1; }


# 7. Verify processes are running under AppArmor
echo "[INFO] Checking process confinement..."
ps auxZ | grep -E 'nginx|bd-socket-plugin' || { echo "[WARN] Processes not found in expected confinement"; }

# 8. Install auditd (if needed, but should be pre-installed)
if ! command -v auditd &> /dev/null; then
    echo "[INFO] Installing auditd for logging..."
    sudo apt update && sudo apt install -y auditd || { echo "[FAIL] Could not install auditd"; exit 1; }
    sudo systemctl enable --now auditd
fi

# 9. Enforce policies after testing
echo "[INFO] Enforcing AppArmor policies..."
sudo aa-enforce /usr/sbin/nginx
sudo aa-enforce /usr/share/ts/bin/bd-socket-plugin

# 10. Final NGINX restart and status check
echo "[INFO] Final NGINX restart..."
sudo systemctl restart nginx || { echo "[FAIL] Final NGINX restart failed"; exit 1; }

echo "[INFO] Checking NGINX status..."
sudo systemctl is-active --quiet nginx && echo "[INFO] NGINX is running" || { echo "[FAIL] NGINX is not running"; exit 1; }


# 11. Verify processes are running under AppArmor
echo "[INFO] Checking process confinement..."
ps auxZ | grep -E 'nginx|bd-socket-plugin' || { echo "[WARN] Processes not found in expected confinement"; }

# 12. Display final AppArmor status
echo "Checking AppArmor status:"
sudo apparmor_status

echo "[SUCCESS] Setup completed." 
