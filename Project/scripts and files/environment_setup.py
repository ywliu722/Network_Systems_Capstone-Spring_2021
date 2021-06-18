import os

# fix the forwarding policy on host
os.system("iptables -P FORWARD ACCEPT")

# Start up the containers
print("Starting h1...")
os.system("docker start h1")
print("Starting h2...")
os.system("docker start h2")
print("Starting BRG1...")
os.system("docker start BRG1")
print("Starting BRG2...")
os.system("docker start BRG2")
print("Starting BRGr...")
os.system("docker start BRGr")
print("Starting edge...")
os.system("docker start edge")
print("Starting r1...")
os.system("docker start r1")

# Build up links
# h1-BRG1
os.system("ip link add h1-eth0 type veth peer name BRG1-eth0")
os.system("ip link set h1-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' h1)")
os.system("ip link set BRG1-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRG1)")
os.system("docker exec -it h1 ip link set h1-eth0 up")
os.system("docker exec -it BRG1 ip link set BRG1-eth0 up")
# h2-BRG2
os.system("ip link add h2-eth0 type veth peer name BRG2-eth0")
os.system("ip link set h2-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' h2)")
os.system("ip link set BRG2-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRG2)")
os.system("docker exec -it h2 ip link set h2-eth0 up")
os.system("docker exec -it BRG2 ip link set BRG2-eth0 up")
# br0 bulid up
os.system("ip link add br0 type bridge")
os.system("ip link set br0 up")
# br0-BRG1
os.system("ip link add br0-veth1 type veth peer name BRG1-eth1")
os.system("ip link set br0-veth1 master br0")
os.system("ip link set BRG1-eth1 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRG1)")
os.system("ip link set br0-veth1 up")
os.system("docker exec -it BRG1 ip link set BRG1-eth1 up")
# br0-BRG2
os.system("ip link add br0-veth2 type veth peer name BRG2-eth1")
os.system("ip link set br0-veth2 master br0")
os.system("ip link set BRG2-eth1 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRG2)")
os.system("ip link set br0-veth2 up")
os.system("docker exec -it BRG2 ip link set BRG2-eth1 up")
# br0-edge
os.system("ip link add br0-veth0 type veth peer name edge-eth1")
os.system("ip link set br0-veth0 master br0")
os.system("ip link set edge-eth1 netns $(sudo docker inspect -f '{{.State.Pid}} ' edge)")
os.system("ip link set br0-veth0 up")
os.system("docker exec -it edge ip link set edge-eth1 up")
# edge-r1
os.system("ip link add edge-eth0 type veth peer name r1-eth0")
os.system("ip link set edge-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' edge)")
os.system("ip link set r1-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' r1)")
os.system("docker exec -it edge ip link set edge-eth0 up")
os.system("docker exec -it r1 ip link set r1-eth0 up")
# BRGr-r1
os.system("ip link add BRGr-eth1 type veth peer name r1-eth1")
os.system("ip link set BRGr-eth1 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRGr)")
os.system("ip link set r1-eth1 netns $(sudo docker inspect -f '{{.State.Pid}} ' r1)")
os.system("docker exec -it BRGr ip link set BRGr-eth1 up")
os.system("docker exec -it r1 ip link set r1-eth1 up")
# BRGr-GWr
os.system("ip link add BRGr-eth0 type veth peer name veth")
os.system("ip link set BRGr-eth0 netns $(sudo docker inspect -f '{{.State.Pid}} ' BRGr)")
os.system("docker exec -it BRGr ip link set BRGr-eth0 up")
os.system("ip link set veth up")