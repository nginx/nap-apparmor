# AppArmor Integration for NGINX App Protect WAF (NAP 4 & 5)

This project provides tools and documentation for integrating **NGINX App Protect WAF (NAP)** versions **4 and 5** with **AppArmor** on **Debian-based systems** (e.g., Ubuntu, Debian).

## Overview

AppArmor is a Linux security module that provides Mandatory Access Control (MAC). When deploying NGINX App Protect WAF, configuring appropriate AppArmor profiles ensures secure, least-privilege access for WAF components, improving system hardening.

This repository includes:

- Custom AppArmor profiles for NGINX and NAP components
- Scripts to apply and test profiles
- Sample test cases to trigger policy denials
- Tools to monitor and troubleshoot AppArmor violations

## Structure
<pre>
.
├── nap4-apparmor/
│   ├── apparmor_policies/
│   ├── test_scripts/
│   ├── README.md
│   └── troubleshooting.md
├── nap5-apparmor/
│   ├── apparmor_policies/
│   ├── test_scripts/
│   ├── README.md
│   └── troubleshooting.md
└── README.md
</pre>

## Requirements

- Debian 11+ or Ubuntu 20.04+ (AppArmor enabled)
- NGINX App Protect WAF v4 or v5 installed
- AppArmor tools: apparmor_parser, aa-status, aa-complain, etc.
