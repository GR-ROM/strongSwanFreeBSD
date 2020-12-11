#!/bin/sh
IFACE=xn0
ADMIN_IP=$MYIP
pkg install -y htop iftop atop nano knock git curl wget
su ec2-user sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "ext_if=\"$IFACE\"
table <knockers> persist
table <bruteforce> persist
table <admins> { $ADMIN_IP }

nat on \$ext_if inet from 10.10.10.0/24 to any port != smtp -> (\$ext_if)

block in all
pass in quick from <admins> to (\$ext_if) keep state
block drop in log quick on \$ext_if from <bruteforce>

pass from { lo0 } to any keep state
pass in proto tcp from any to (\$ext_if) port { 7000, 8000, 9000 }

pass in proto tcp from any to (\$ext_if) port 22 keep state (max-src-conn 3, max-src-conn-rate 3/30, overload <bruteforce> flush global)
pass in proto udp from <knockers> to (\$ext_if) port 500 keep state
pass in proto udp from <knockers> to (\$ext_if) port 4500 keep state

pass in proto tcp from any to (\$ext_if) port 443 keep state (max-src-conn 50, max-src-conn-rate 50/10, overload <bruteforce> flush global)

pass out all" > /etc/pf.conf

echo "hostname=\"freebsd\"
ec2_configinit_enable=YES
ec2_fetchkey_enable=YES
ec2_loghostkey_enable=YES
firstboot_freebsd_update_enable=YES
firstboot_pkgs_enable=YES
ntpd_enable=YES
growfs_enable=YES
ifconfig_DEFAULT=\"SYNCDHCP accept_rtadv\"
sshd_enable=YES
firstboot_pkgs_list=awscli
ipv6_activate_all_interfaces=YES
dhclient_program=\"/usr/local/sbin/dual-dhclient\"

gateway_enable=YES

pf_enable=NO
pf_rules=\"/etc/pf.conf\"
pf_flags=\"\"
pflog_enable=YES
pflog_logfile=\"/var/log/pflog\"
pflog_flags=\"\"

strongswan_enable=YES
knockd_enable=YES" > /etc/rc.conf
kldload pf.ko
pfctl -e
pfctl -f /etc/pf.conf

echo "[options]
        logfile = /var/log/knockd.log
        interface = xn0

[openSSH]
        sequence    = 7000,8000,9000
        seq_timeout = 5
        command     = /sbin/pfctl -t knockers -T add %IP%
        tcpflags    = syn
[closeSSH]
        sequence    = 9000,8000,7000
        seq_timeout = 5
        command     = /sbin/pfctl -t knockers -T delete %IP%
        tcpflags    = syn" > /usr/local/etc/knockd.conf
service knockd restart
