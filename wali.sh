#!/bin/bash
trap ' ' 2
sudo apt-get update -y
ipvps=`wget http://ipecho.net/plain -O - -q ; echo`
sudo apt-get install nano -y; sudo apt-get install curl -y
sudo apt-get install chmod -y; sudo apt-get install dpkg -y
# ===
cekos=`sudo lsb_release -d`
cekbit=`sudo uname -m`
# ===
if [[ `ifconfig -a | grep "venet0"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "eth0"` ]]
then
cekvirt='KVM'
fi
# ================================================================================​==
# ================== Places Function you need ======================================
# 1===
funct_update()
{
sudo apt-get update -y
cd
}
# 2===
funct_upgrade()
{
sudo apt-get upgrade -y
cd
}
# 3===
funct_webmin()
{
sudo echo 'deb http://download.webmin.com/download/repository sarge contrib' >> /etc/apt/sources.list
sudo echo 'deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib' >> /etc/apt/sources.list
wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc
sudo apt-get update -y
sudo apt-get install webmin -y
sudo echo '/bin/false' >> /etc/shells
funct_update
cd
}
# 4===
funct_openssh()
{
sudo sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sudo sed -i 's/# Port 22/Port 22/g' /etc/ssh/sshd_config
# ===
sudo sed -i '/^Port 22/ s:$:\nPort 109:' /etc/ssh/sshd_config
sudo sed -i '/^Port 22/ s:$:\nPort 53:' /etc/ssh/sshd_config
cd
}
# 5===
funct_apache()
{
sudo sed -i 's/NameVirtualHost *:80/NameVirtualHost *:88/g' /etc/apache2/ports.conf
sudo sed -i 's/Listen 80/Listen 88/g' /etc/apache2/ports.conf
sudo service apache2 restart
cd
}
# 6===
funct_dropbear()
{
sudo apt-get install dropbear -y
# ===
sudo sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sudo sed -i 's/DROPBEAR_PORT=22/# DROPBEAR_PORT=22/g' /etc/default/dropbear
sudo sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 443 -p 143"/g' /etc/default/dropbear
cd
}
# 7===
funct_squid()
{
sudo apt-get install squid3 -y
sudo echo 'acl server1 dst '$ipvps'-'$ipvps'/255.255.255.255' >> /etc/squid3/squid.conf
sudo echo 'http_access allow server1' >> /etc/squid3/squid.conf
sudo echo 'http_port 80' >> /etc/squid3/squid.conf
sudo echo 'http_port 8080' >> /etc/squid3/squid.conf
sudo echo 'http_port 8000' >> /etc/squid3/squid.conf
# ===
sudo echo 'forwarded_for off' >> /etc/squid3/squid.conf
sudo echo 'visible_hostname server1' >> /etc/squid3/squid.conf
cd
}
# 8===
funct_openvpn()
{
sudo apt-get install openvpn -y
# ===
if [ ! -d "/usr/share/doc/openvpn/examples/easy-rsa" ]
then
cd /etc/openvpn/
wget http://cznic.dl.sourceforge.net/project/vpsmanagement/Other/easy-rsa.tar.gz
sudo tar -xzf /etc/openvpn/easy-rsa.tar.gz
else
sudo cp -a /usr/share/doc/openvpn/examples/easy-rsa /etc/openvpn/
fi
cd /etc/openvpn/easy-rsa/2.0
sudo chmod +x *; source ./vars; ./vars; ./clean-all
./build-ca; ./build-key-server server; ./build-dh
# ===
sudo cp -r /etc/openvpn/easy-rsa/2.0/keys/ /etc/openvpn/keys/
sudo cp /etc/openvpn/keys/ca.crt /etc/openvpn/
cd /etc/openvpn/
# ===
sudo echo -e 'dev tun*' > server.conf
# ===
sudo echo -e 'port 1194' >> myserver.conf
sudo echo -e 'proto tcp' >> myserver.conf
sudo echo -e 'dev tun' >> myserver.conf
sudo echo -e 'ca /etc/openvpn/keys/ca.crt' >> myserver.conf
sudo echo -e 'dh /etc/openvpn/keys/dh1024.pem' >> myserver.conf
sudo echo -e 'cert /etc/openvpn/keys/server.crt' >> myserver.conf
sudo echo -e 'key /etc/openvpn/keys/server.key' >> myserver.conf
if [ $cekvirt = "OpenVZ" ]
then
  sudo echo -e 'plugin /usr/lib/openvpn/openvpn-auth-pam.so /etc/pam.d/login' >> myserver.conf
else
  sudo echo -e 'plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so /etc/pam.d/login' >> myserver.conf
fi
sudo echo -e 'client-cert-not-required' >> myserver.conf
sudo echo -e 'username-as-common-name' >> myserver.conf
sudo echo -e 'server 10.8.0.0 255.255.255.0' >> myserver.conf
sudo echo -e 'ifconfig-pool-persist ipp.txt' >> myserver.conf
sudo echo -e 'push "redirect-gateway def1"' >> myserver.conf
sudo echo -e 'push "dhcp-option DNS 8.8.8.8"' >> myserver.conf
sudo echo -e 'push "dhcp-option DNS 8.8.4.4"' >> myserver.conf
sudo echo -e 'keepalive 5 30' >> myserver.conf
sudo echo -e 'comp-lzo' >> myserver.conf
sudo echo -e 'persist-key' >> myserver.conf
sudo echo -e 'persist-tun' >> myserver.conf
sudo echo -e 'status server-tcp.log' >> myserver.conf
sudo echo -e 'verb 3' >> myserver.conf
# ===
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
# ===
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
# ===
if [ $cekvirt = "OpenVZ" ]
then
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o venet0 -j SNAT --to $ipvps
# iptables -t nat -A POSTROUTING -o venet0 -j SNAT --to-source $ipvps
else
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
#sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j SNAT --to $ipvps
fi
sudo apt-get install iptables-persistent
funct_update
sudo service openvpn restart
cd
# REMOVE IPTABLES All
# sudo iptables -P INPUT ACCEPT; sudo iptables -P FORWARD ACCEPT; sudo iptables -P OUTPUT ACCEPT
# sudo iptables -t nat -F; sudo iptables -t mangle -F; sudo iptables -F; sudo iptables -X
}
# 9===
funct_badvpn()
{
if [[ `echo $cekos | grep "Debian" ` ]]
then
  sudo apt-get install make cmake gcc -y
  wget http://badvpn.googlecode.com/files/badvpn-1.999.128.tar.bz2
  sudo tar xf badvpn-1.999.128.tar.bz2; mkdir badvpn-build; cd badvpn-build
  sudo cmake ~/badvpn-1.999.128 -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
  sudo make install
elif [[ `echo $cekos | grep "Ubuntu" ` ]]
then
  sudo add-apt-repository ppa:ambrop7/badvpn -y
  sudo apt-get update -y
  sudo apt-get install badvpn -y
fi
# ===
sudo badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &
sudo sed -i 's/exit 0/# ====/g' /etc/rc.local
sudo echo -e 'badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/nul &' >> /etc/rc.local
sudo echo -e 'exit 0' >> /etc/rc.local
cd
}
# 10===
funct_pptpvpn()
{
sudo apt-get install pptpd -y
sudo echo 'localip '$ipvps >> /etc/pptpd.conf
sudo echo 'remoteip 10.10.0.1-200' >> /etc/pptpd.conf
sudo echo 'ms-dns 8.8.8.8' >> /etc/ppp/pptpd-options
sudo echo 'ms-dns 8.8.4.4' >> /etc/ppp/pptpd-options
# === add user pptp
sudo echo '#username[tabkey]pptpd[tabkey]password[tabkey]ipremoteclient' >> /etc/ppp/chap-secrets
sudo echo 'user1 pptpd pass1 10.10.0.1' >> /etc/ppp/chap-secrets
sudo echo 'user2 pptpd pass2 10.10.0.2' >> /etc/ppp/chap-secrets
sudo echo 'user3 pptpd pass3 10.10.0.3' >> /etc/ppp/chap-secrets
# ===
sudo echo 'ifconfig $1 mtu 1400' >> /etc/ppp/ip-up
# ===
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
# ===
if [ $cekvirt = "OpenVZ" ]
then
  # OVZ virtualization
  sudo iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o venet0 -j SNAT --to $ipvps
  # sudo iptables -t nat -A POSTROUTING -j SNAT --to-source $ipvps  
else
  # KVM virtualization
  sudo iptables --table nat -A POSTROUTING -o eth0 -j MASQUERADE
fi
# ===
sudo apt-get install iptables-persistent
funct_update
echo -e '\n'
echo -e 'default user have been create as :'
sudo cat < /etc/ppp/chap-secrets | grep "10.10"
echo -e 'edit "/etc/ppp/chap-secrets" to adduser more \n'
echo -e 'Continue \c'
cd
}
# 11===
funct_softvpn()
{
echo -e "Script un-config yet \n"
cd
}
# 12===
funct_fail2ban()
{
echo -e "Script un-config yet \n"
cd
}
# 13===
funct_userlogin()
{
sudo curl -s http://hivelocity.dl.sourceforge.net/project/vpsmanagement/Other/user-login.sh > user-login.sh
sudo chmod +x user-login.sh
cd
}
# 14===
funct_speedtest()
{
sudo apt-get install python -y
wget https://github.com/sivel/speedtest-cli/raw/master/speedtest_cli.py
sudo chmod a+rx speedtest_cli.py
cd
}
# 15===
funct_setall()
{
funct_update
funct_upgrade
funct_webmin
funct_openssh
funct_apache
funct_dropbear
funct_squid
funct_openvpn
funct_badvpn
funct_pptpvpn
funct_fail2ban
funct_userlogin
funct_speedtest
funct_react
cd
}
# 16===
funct_react()
{
sudo service apache2 restart
sudo service squid3 restart
sudo service ssh restart
sudo service dropbear restart
sudo service webmin restart
sudo pptpd restart
sudo ./user-login.sh
sudo python speedtest_cli.py --share
sudo netstat -ntlp
cd
}
# AUTO SCRIPT DEBIAN ==
clear
while true
do
  clear
  echo "===================================================="
  echo "            DEBIAN-UBUNTU VPS MANAGEMENT            "
  echo "===================================================="
  echo $cekos - $cekbit
  echo "Virtualization : $cekvirt"
  sudo cat /dev/net/tun
  sudo cat /dev/ppp
  echo "===================================================="
  echo " 1. Update                ||  8. OPEN VPN           "
  echo " 2. Upgrade               ||  9. BAD VPN            "
  echo " 3. Webmin                || 10. PPTP VPN           "
  echo " 4. Managed Port OpenSSH  || 11. VPN Server         "
  echo " 5. Managed Port Apache2  || 12. Fail2Ban           "
  echo " 6. Dropbear              || 13. Script User-Login  "
  echo " 7. Squid3                || 14. add Speedtest-CLI  "
  echo "===================================================="
  echo "15. Setup All in One"
  echo "16. Restart All Managed"
  echo "17. Exit"
  echo -e "\n"
  echo -e "Type number choice : \c"
  read choice
  case "$choice" in
    1) funct_update ;;
    2) funct_upgrade ;;
    3) funct_webmin ;;
    4) funct_openssh ;;
    5) funct_apache ;;
    6) funct_dropbear ;;
    7) funct_squid ;;
    8) funct_openvpn ;;
    9) funct_badvpn ;;
   10) funct_pptpvpn ;;
   11) funct_softvpn ;;
   12) funct_fail2ban ;;
   13) funct_userlogin ;;
   14) funct_speedtest ;;
   15) funct_setall ;;
   16) funct_react ;;
   17) exit ;;
  esac
  echo -e 'Enter return to Continue \c'
  read input
done
