import os

# static IP set up
os.system("docker exec -it edge ip addr add 140.114.0.1/16 dev edge-eth0")
os.system("docker exec -it edge ip addr add 172.27.0.1/16 dev edge-eth1")
os.system("docker exec -it r1 ip addr add 140.114.0.2/16 dev r1-eth0")
os.system("docker exec -it r1 ip addr add 140.113.0.1/16 dev r1-eth1")
os.system("docker exec -it BRGr ip addr add 140.113.0.2/16 dev BRGr-eth1")
os.system("ip address add 20.0.0.1/8 dev veth")
# DHCP server set up
os.system("docker exec -it edge /usr/sbin/dhcpd 4 -pf /run/dhcp-server-dhcpd.pid -cf ./dhcpd.conf edge-eth1")
os.system("/usr/sbin/dhcpd 4 -pf /run/dhcp-server-dhcpd.pid -cf ./dhcpd_outer.conf veth")
# BRG1/BRG2 requst IP from edge DHCP server
os.system("docker exec -it BRG1 dhclient BRG1-eth1")
os.system("docker exec -it BRG2 dhclient BRG2-eth1")
# static route set up
os.system("docker exec -it edge ip route add 140.113.0.0/16 via 140.114.0.2")
os.system("docker exec -it BRGr ip route add 140.114.0.0/16 via 140.113.0.1")
os.system("docker exec -it BRGr ip route add default dev BRGr-eth0")
os.system("docker exec -it BRG1 ip route add 20.0.0.1/32 via 172.27.0.1")
os.system("docker exec -it BRG1 ip route add 20.0.0.0/8 dev BRG1-eth0")
os.system("docker exec -it BRG2 ip route add 20.0.0.1/32 via 172.27.0.1")
os.system("docker exec -it BRG2 ip route add 20.0.0.0/8 dev BRG2-eth0")
# NAT rule set up
os.system("docker exec -it edge iptables -t nat -A POSTROUTING -s 172.27.0.0/16 -j MASQUERADE")
os.system("iptables -t nat -A POSTROUTING -s 20.0.0.0/8 -j MASQUERADE")
# Auto Creation Program
os.system("make")
os.system("docker cp ./0716236 BRGr:/")