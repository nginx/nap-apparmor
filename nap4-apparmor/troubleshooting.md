## Troubleshooting Apparmor Issues

### 1. Modify the existing rules in the apparmor file as given below (/etc/apparmor.d/usr.sbin.nginx)

```shell
cd /etc/apparmor.d

sudo vim usr.sbin.nginx
```

#modify line '/run/nginx.pid rwk,' to below
```shell
deny /run/nginx.pid x,
```

### 2. Reload the policy file 

```shell
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

### 3. Run test_apparmor script

```shell
cd ~/nap-apparmor/nap4-apparmor/

sudo ./test_scripts/test_apparmor.sh
```

### 4. Check for apparmor Denials

Any denials from above script will be displayed on the console or can check under /etc/app_protect/apparmor_denial_logs 

View all apparmor denials manually with:

```shell
sudo journalctl | grep -E "(DENIED)"
```
**Denial Example for the above policy:**  

a. **/run/nginx.pid (Delete/Unlink Denial):** 

Jun 30 05:28:23 nap-vm-test-local-debian-bullseye-vm-instance-0 audit[204645]: AVC apparmor="DENIED" operation="unlink" profile="/usr/sbin/nginx" name="/run/nginx.pid" pid=204645 comm="nginx" requested_mask="d" denied_mask="d" fsuid=0 ouid=0

unlink denial – NGINX was blocked from deleting the existing /run/nginx.pid file during restart.

b. **/run/nginx.pid (Creation denial):**  

Jun 30 05:28:24 nap-vm-test-local-debian-bullseye-vm-instance-0 audit[204780]: AVC apparmor="DENIED" operation="mknod" profile="/usr/sbin/nginx" name="/run/nginx.pid" pid=204780 comm="nginx" requested_mask="c" denied_mask="c" fsuid=0 ouid=0

mknod denial – NGINX was denied permission to create a new /run/nginx.pid file after deletion

c. **/run/nginx.pid (Read denial):**

Jun 30 05:29:11 nap-vm-test-local-debian-bullseye-vm-instance-0 audit[204891]: AVC apparmor="DENIED" operation="open" profile="/usr/sbin/nginx" name="/run/nginx.pid" pid=204891 comm="nginx" requested_mask="r" denied_mask="r" fsuid=0 ouid=0

open denial – NGINX was prevented from reading the /run/nginx.pid file during startup checks.

### 5. Generating Policy Rules

Use `sudo aa-logprof` to create policy rules from denials:
```shell
sudo aa-logprof 
```
**Example output for the above denial:**  

Reading log entries from /var/log/audit/audit.log.
Updating AppArmor profiles in /etc/apparmor.d.

Profile: /usr/sbin/nginx  
Path:    /run/nginx.pid  
New Mode: owner w  
Severity: unknown  
 [1 - owner /run/nginx.pid w,]  
 
 (A)llow / [(D)eny] / (I)gnore / (G)lob / Glob with (E)xtension / (N)ew /  
 Audi(t) / (O)wner permissions off / Abo(r)t / (F)inish

Profile: /usr/sbin/nginx  
Path:    /run/nginx.pid  
Old Mode: owner w  
New Mode: owner r  
Severity: unknown  
 [1 - owner /run/nginx.pid r,]  
 
 (A)llow / [(D)eny] / (I)gnore / (G)lob / Glob with (E)xtension / (N)ew /  
 Audi(t) / (O)wner permissions off / Abo(r)t / (F)inish


By typing A(allow),and S(saving) it will automatically add rules to the policy. Or you can add them manually as given below(1st point).

### 6. Applying Fixes

1. Add the generated rules to your custom policy (usr.sbin.nginx)

```shell
   owner /run/nginx.pid rw,
```

2. Reload the policy 
```shell
    sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

3. Run test_apparmor.sh again
```shell
    sudo ./test_scripts/test_apparmor.sh
```

### 7. Verification 
Repeat steps 4 through 6, addressing each apparmor denial and re-testing until the system shows no additional policy denials or test failures. When this condition is met, you've finalized a policy that supports NGINX App Protect without restrictions.

```shell
sudo journalctl -f | grep -E "(DENIED)"
```
