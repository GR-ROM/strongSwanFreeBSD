#!/bin/sh
pkg update -y
pkg install -y strongswan
mkdir ~/pki/cacerts
mkdir ~/pki/certs
mkdir ~/pki/private
chmod -R 700 ~/pki

IP="35.157.147.9"
ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem
ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
 --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem
ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem
ipsec pki --pub --in ~/pki/private/server-key.pem --type rsa \
| ipsec pki --issue --lifetime 1825 \
--cacert ~/pki/cacerts/ca-cert.pem \
--cakey ~/pki/private/ca-key.pem \
--dn "CN=$IP" --san "$IP" \
--flag serverAuth --flag ikeIntermediate --outform pem \
 >  ~/pki/certs/server-cert.pem

cp -r ~/pki/* /usr/local/etc/ipsec.d/

