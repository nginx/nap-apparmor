# NGINX App Protect 5 WAF with Apparmor Integration

This project provides tools and documentation for integrating NGINX App Protect 5 WAF with apparmor on Debian-based systems.

## Overview
NGINX App Protect 5 WAF (Web Application Firewall) integration with apparmor provides an additional layer of security on debian systems. This repository contains apparmor policies, installation scripts, and testing utilities designed for NGINX App Protect 5 deployments.

> **⚠️ Important**: This guide uses a **system that supports systemd** (such as a VM or physical server) and **cannot be run on standard Docker containers or kubernetes deployments****. The test scripts use `systemctl` commands and require full systemd service management capabilities that are not available in most containerized environments.
However, as long as NGINX is deployed on the host system, you can still test and validate SELinux policies, even if NGINX App Protect WAF components run in containers.


## Prerequisites and Dependencies
### System Requirements
- **Operating System:** Debian 11 (Bullseye) or newer
- **Package Repositories:** Access to official Debian repositories and package updates
- **Apparmor** Must be available and enabled on the system
- **NGINX App Protect 5:** Ensure NGINX App Protect WAF is installed on your system with valid license files (nginx-repo.crt, nginx-repo.key).
- **nginx.conf:** Make sure there is valid nginx.conf file under /etc/nginx/nginx.conf
- **Root/sudo access:** Required for installation and configuration


## Steps and Dependencies
### 1. Operating System Validation
* Check if your OS and version are supported for AppArmor testing.
* For example, supported versions might include Debian 11 (Bullseye), Debian 12 (Bookworm), and Ubuntu 20.04 LTS, 22.04 LTS, but adjust as needed for your environment.
* If your OS/version is not supported, update your dependencies or consult your vendor documentation.
* Verify AppArmor is enabled and available on your system.

### 2. Package Installation and Updates
* All required packages for AppArmor profile development, cryptographic setup, and system integration are installed automatically during the environment setup process.
* **The setup process installs the following packages:**
   * `apt-transport-https` - Enables HTTPS support for APT package manager.
   * `lsb-release` - Provides standardized OS/distribution information.
   * `ca-certificates` - Installs trusted CA certificates for SSL/TLS.
   * `wget` - Command-line tool for downloading files via HTTP, HTTPS, and FTP.
   * `gnupg2` - Complete GnuPG suite for cryptographic operations and repository authentication.
* **Common AppArmor-related packages include:**
  * `apparmor` - Core AppArmor security framework
  * `apparmor-utils` - AppArmor userspace utilities and tools
  * `apparmor-profiles` - Base set of AppArmor profiles
  * `libapparmor1` - AppArmor runtime library
  * `python3-apparmor` - Python 3 bindings for AppArmor
  * `python3-libapparmor` - Python 3 library for AppArmor
* **System Monitoring and Integration:**
  * `curl` - Command-line tool for downloading AppArmor profiles, policy templates, and remote security resources.
  * `systemd` - System service manager integration for AppArmor-aware service management and profile loading.
  * `vim` - Text editor with AppArmor syntax highlighting support for profile development and policy editing.
* If your application requires additional packages (e.g., `libssl-dev` for cryptography libraries, web server packages), add them to your dependency files.

### 3. Certificate and License Management
* If your application uses SSL/TLS or license files, ensure the necessary directories exist and files are copied to the correct locations.
* Validate certificates and keys as required.
* Adjust file locations and permissions based on your application's needs.

### 4. Repository and Subscription Management
* Ensure your system can access the required repositories(apt) for package management.
* For Debian systems, verify `/etc/apt/sources.list` and `/etc/apt/sources.list.d/` contain the correct repository URLs for your Debian version.
* For Ubuntu systems, ensure standard repositories (main, restricted, universe, multiverse) are enabled as needed.

### 5. AppArmor Enforcement Checks
* Verify that AppArmor is enabled and actively enforcing profiles on the system.
* Ensure all required AppArmor packages and development tools are installed to support profile creation and management.

  ```bash
  # Check AppArmor status
  sudo aa-status

  # Check if AppArmor is enabled in kernel
  sudo cat /sys/module/apparmor/parameters/enabled

  # Verify AppArmor packages are installed
  dpkg -l | grep -E "(apparmor|libapparmor)"

  # Check apparmor version
  sudo apt-cache policy apparmor
  ```
### 6. Supported NAP5 Deployment Model
This setup supports NGINX deployment on a host (Debian VM) with containerized NGINX App Protect WAF (NAP5) components.
* Test Apparmor policy integration between host NGINX and containerized WAF.
* Validate system-level security policies with container-based functionality.


## Installation

### 1. Clone Repository

```bash
#command to install git if not present
sudo apt update && sudo apt install -y git

sudo git clone <repository-url>
```

### Step 2: Prepare Installation Files

Ensure the following files are present under /apparmor_policies directory before running the installation script:

- `usr.sbin.nginx`
- `usr.share.ts.bd-socket-plugin`

### 3. Execute Installation Script

Make the installation script executable and run it:

```bash
cd nap-apparmor/nap5-apparmor

sudo ./apparmor_policies/build_install.sh
```

The installation script will:
- Reload AppArmor policies
- Set profiles to complain mode initially
- Test configuration
- Switch to enforce mode
- Restart services

### 4. Run Test Suite

Execute the comprehensive test suite to verify the installation:

```bash
# Run tests
sudo ./test_scripts/test_apparmor.sh
```

## Configuration

### AppArmor Profiles

This repository includes two main AppArmor profiles:

- **`usr.sbin.nginx`**: Main NGINX process profile
- **`usr.share.ts.bd-socket-plugin`**: App Protect plugin profile

### Profile Modes

- **Complain Mode**: Logs violations without blocking (used during setup)
- **Enforce Mode**: Actively blocks unauthorized operations (production mode)

### Manual Profile Management

```bash
# Set to complain mode
sudo aa-complain /usr/sbin/nginx

# Set to enforce mode  
sudo aa-enforce /usr/sbin/nginx

# Check profile status
sudo aa-status | grep nginx
```

## Testing

### Automated Testing

The test suite includes:

- Service start/stop/restart tests
- HTTP connectivity tests
- Nginx configuration validation and App Protect functionality tests

### Manual Testing

```bash
# Test basic NGINX functionality
curl localhost

# Check AppArmor logs for denials
sudo journalctl -f | grep -E "(DENIED)"

# Monitor audit logs
sudo cat /var/log/audit/audit.log | grep -E "apparmor"
```

##  Troubleshooting

### Common Issues

#### 1. NGINX Fails to Start After AppArmor Enforcement

**Solution**: Check AppArmor logs and add missing permissions:

```bash
sudo journalctl -xe | grep apparmor
sudo systemctl restart nginx
```

#### 2. App Protect Configuration Denials

**Solution**: Verify App Protect paths are allowed in the profile:

```bash
sudo grep -n "app_protect" /etc/apparmor.d/usr.sbin.nginx
```

#### 3. Permission Denied for Temporary Files

**Solution**: Add write permissions for App Protect temporary directories:

```bash
# Edit the profile
sudo vim /etc/apparmor.d/usr.sbin.nginx

# Add paths like:
# /opt/app_protect/config/** rw,
# /tmp/app_protect/** rw,
```

### Debug Commands

```bash
# Check AppArmor status
sudo aa-status

# View AppArmor denials
sudo journalctl -f | grep -E "DENIED|apparmor"

# Test NGINX configuration
sudo nginx -t

# Check service status
sudo systemctl status nginx nginx-app-protect
```

### Log Locations

- **AppArmor logs**: `sudo journalctl -f | grep -E "apparmor"
- **NGINX logs**: `/var/log/nginx/`


## Security Considerations

- Always test profiles in complain mode before enforcing
- Regularly review AppArmor logs for policy violations
- Keep profiles updated with App Protect version changes
- Monitor for new App Protect features that may require profile updates
