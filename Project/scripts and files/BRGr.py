import os

os.system("docker exec -it BRGr ip fou add port 33333 ipproto 47")
os.system("docker exec -it BRGr ip link add GRE1 type gretap remote 140.114.0.1 local 140.113.0.2 key 11111 encap fou encap-sport 33333 encap-dport 11111")
os.system("docker exec -it BRGr ip link set GRE1 up")
os.system("docker exec -it BRGr ip link add br0 type bridge")
os.system("docker exec -it BRGr brctl addif br0 BRGr-eth0")
os.system("docker exec -it BRGr brctl addif br0 GRE1")
os.system("docker exec -it BRGr ip link set br0 up")

os.system("docker exec -it BRGr ip fou add port 44444 ipproto 47")
os.system("docker exec -it BRGr ip link add GRE2 type gretap remote 140.114.0.1 local 140.113.0.2 key 22222 encap fou encap-sport 44444 encap-dport 22222")
os.system("docker exec -it BRGr ip link set GRE2 up")
os.system("docker exec -it BRGr brctl addif br0 GRE2")