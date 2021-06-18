import os

os.system("modprobe fou")
# TUNNEL
os.system("docker exec -it BRG1 ip fou add port 11111 ipproto 47")
os.system("docker exec -it BRG1 ip link add GRE type gretap remote 140.113.0.2 local 172.27.140.236 key 11111 encap fou encap-sport 11111 encap-dport 33333")
os.system("docker exec -it BRG1 ip link set GRE up")
os.system("docker exec -it BRG1 ip link add br0 type bridge")
os.system("docker exec -it BRG1 brctl addif br0 BRG1-eth0")
os.system("docker exec -it BRG1 brctl addif br0 GRE")
os.system("docker exec -it BRG1 ip link set br0 up")

os.system("docker exec -it BRG2 ip fou add port 22222 ipproto 47")
os.system("docker exec -it BRG2 ip link add GRE type gretap remote 140.113.0.2 local 172.27.140.237 key 22222 encap fou encap-sport 22222 encap-dport 44444")
os.system("docker exec -it BRG2 ip link set GRE up")
os.system("docker exec -it BRG2 ip link add br0 type bridge")
os.system("docker exec -it BRG2 brctl addif br0 BRG2-eth0")
os.system("docker exec -it BRG2 brctl addif br0 GRE")
os.system("docker exec -it BRG2 ip link set br0 up")