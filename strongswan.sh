#!/bin/sh
rm -rf ~/pki
mkdir ~/pki
mkdir ~/pki/cacerts
mkdir ~/pki/certs
mkdir ~/pki/private
chmod -R 700 ~/pki

IP=3.71.237.223
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

cp ~/pki/certs/server-cert.pem /usr/local/etc/swanctl/x509
cp ~/pki/cacerts/ca-cert.pem /usr/local/etc/swanctl/x509ca
cp ~/pki/private/* /usr/local/etc/swanctl/private

echo "connections {
   ikev2-cert {
      version = 2
      send_cert = always
      encap = yes
      pools = pool1
      dpd_delay = 60s
      proposals = aes256-aes128-sha256-sha1-modp3072-modp2048-modp1024
      local {
         certs = server-cert.pem
         id = vpnserver
      }
      remote {
         auth = eap-mschapv2
         eap_id = %any
      }
      children {
         net {
            local_ts  = 0.0.0.0
            esp_proposals = aes256-aes128-sha256-sha1-modp3072-modp2048-modp1024
         }
      }
   }
}

pools {
   pool1 {
     addrs = 10.10.10.0/24
     dns = 8.8.8.8
   }
}

secrets {
  eap_roman {
    id = roman
    secret = 123456
  }
}" > /usr/local/etc/swanctl/swanctl.conf

echo "# strongswan.conf - strongSwan configuration file
#
# Refer to the strongswan.conf(5) manpage for details
#
# Configuration changes should be made in the included files

charon {
        load_modular = yes

filelog {
    charon {
      # path to the log file, specify this as section name in versions prior to 5.7.0
      path = /var/log/charon.log
      # add a timestamp prefix
      time_format = %b %e %T
      # prepend connection name, simplifies grepping
      ike_name = yes
      # overwrite existing files
      append = no
      # increase default loglevel for all daemon subsystems
      default = 2
      # flush each line to disk
      flush_line = yes
    }
    stderr {
      # more detailed loglevel for a specific subsystem, overriding the
      # default loglevel.
      ike = 2
      knl = 3
    }
  }
        plugins {
                include strongswan.d/charon/*.conf
        }
}" > /usr/local/etc/strongswan.conf
