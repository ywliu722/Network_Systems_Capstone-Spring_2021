#include <iostream>
#include <pcap.h>
#include <vector>
#include <string>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <netinet/ip.h>
#include <cstring>
#include <stdlib.h>

using namespace std;
pcap_t *handler;
bool bridge_stats=false;
int packet_number = 1;
char IP[11];
char errbuf[PCAP_ERRBUF_SIZE];
string filter_exp;
bpf_u_int32 subnet_mask, ip;
char* find_devices(){
    // Define necessary variables
    vector<char*> device_list;
    device_list.clear();
    int index=0;
    pcap_if_t *devices = NULL;

    // Get the device list
    if(pcap_findalldevs(&devices, errbuf) == -1) {
        fprintf(stderr, "pcap_findalldevs(): %s\n", errbuf);
        exit(1);
    }

    // Go through the device list
    for(pcap_if_t *d = devices ; d ; d = d->next) {
        cout<<index<<" Name: "<<d->name<<endl;
        device_list.push_back(d->name);
        index++;
    }

    // Let user select the device
    int device_num=0;
    string input;
    cout<<"Insert a number to select interface"<<endl;
    getline(cin, input);
    device_num = atoi(input.c_str());
    
    return device_list[device_num];
}

void open_device(char* selected_device){
    handler = pcap_open_live(selected_device, BUFSIZ, 1, 0, errbuf);
    if(handler == NULL){
        fprintf(stderr, "pcap_open_live(): %s\n", errbuf);
        exit(1);
    }
    cout<<"Start listening at $"<<selected_device<<endl;
}

void packet_processing(u_char *args, const struct pcap_pkthdr *packet_header, const u_char *packet){
    struct ether_header *ep, *ep_inside;
    struct ip *iph;
    unsigned short ether_type, ether_type_inside;

    printf("Packet Num [%d]\n",packet_number);

    // Print byte codes of all captured packets in Hexadecimal
    for(int j=0;j<packet_header->len;j++){
        if(j%2){
            printf("%.2X ",(unsigned char) packet[j]);
        }
        else{
            printf("%.2X",(unsigned char) packet[j]);
        }
        if(j%16==15){
            printf("\n");
        }
    }
    printf("\n");

    // Outer Ethernet header
    ep = (struct ether_header *)packet;
    printf("Outer Source MAC:  ");
    for (int i=0; i<ETH_ALEN-1; ++i){
        printf("%.2X:", ep->ether_shost[i]);
    }
    printf("%.2X\n", ep->ether_shost[ETH_ALEN-1]);

    printf("Outer Destination MAC:  ");
    for (int i=0; i<ETH_ALEN-1; ++i){
        printf("%.2X:", ep->ether_dhost[i]);
    }
    printf("%.2X\n", ep->ether_dhost[ETH_ALEN-1]);

    // Get upper protocol type.
    ether_type = ntohs(ep->ether_type);
    printf("Outer Ether Type: 0x%.4X\n\n",ether_type);
    // Move packet pointer for upper protocol header.
    packet += sizeof(struct ether_header);
    // Outer IP header
    if (ether_type == ETHERTYPE_IP) {
        printf("Ethernet type:  IPv4\n");
        iph = (struct ip *)packet;
        printf("Outer Src IP:  %s\n", inet_ntoa(iph->ip_src));
        printf("Outer Dst IP:  %s\n", inet_ntoa(iph->ip_dst));
        if((int)iph->ip_p == 47){
            printf("Next Layer Protocol:  GRE\n\n");
        }
        packet+=sizeof(struct ip);
    }
    // GRE header
    printf("Protocol type:  0x");
    packet+=2;
    printf("%.2X",(unsigned char) *packet);
    packet++;
    printf("%.2X\n\n",(unsigned char) *packet);
    packet++;

    // Inner Ethernet header
    ep_inside = (struct ether_header *)packet;
    printf("Inner Source MAC:  ");
    for (int i=0; i<ETH_ALEN-1; i++){
        printf("%.2X:", ep_inside->ether_shost[i]);
    }
    printf("%.2X\n", ep_inside->ether_shost[ETH_ALEN-1]);

    printf("Inner Destination MAC:  ");
    for (int i=0; i<ETH_ALEN-1; i++){
        printf("%.2X:", ep_inside->ether_dhost[i]);
    }
    printf("%.2X\n", ep_inside->ether_dhost[ETH_ALEN-1]);
    ether_type_inside = ntohs(ep_inside->ether_type);
    printf("Inner Ether Type: 0x%.4X\n",ether_type_inside);

    // Tunnel Creation
    bool flag = true;
    for(int i=0;i<8;i++){
        if(IP[i] != inet_ntoa(iph->ip_dst)[i]){
           flag=false;
        }
    }
    if(flag){
        string srcIP, dstIP;
        char command1[100], command2[50], command3[50];
        char* tmp_IP = inet_ntoa(iph->ip_src);
        for(int i=0;i<strlen(tmp_IP);i++){
            srcIP+=tmp_IP[i];
        }
        tmp_IP = inet_ntoa(iph->ip_dst);
        for(int i=0;i<strlen(tmp_IP);i++){
            dstIP+=tmp_IP[i];
        }

        sprintf(command1, "ip link add GRE%d type gretap remote %s local %s", packet_number, srcIP.c_str(), dstIP.c_str());
        printf("%s\n",command1);
        system(command1);
        sprintf(command2, "ip link set GRE%d up", packet_number);
        printf("%s\n",command2);
        system(command2);
        if(!bridge_stats){
            system("ip link add br0 type bridge");
            system("brctl addif br0 BRGr-eth0");
        }
        sprintf(command3, "brctl addif br0 GRE%d", packet_number);
        printf("%s\n",command3);
        system(command3);
        if(!bridge_stats){
            system("ip link set br0 up");
        }
        bridge_stats = true;

        // Update filter expression
        filter_exp += " && host not "+srcIP;
        struct bpf_program filter;
        if (pcap_compile(handler, &filter, filter_exp.c_str(), 0, ip) == -1) {
            printf("Bad filter - %s\n", pcap_geterr(handler));
            exit(1);
        }
        if (pcap_setfilter(handler, &filter) == -1) {
            printf("Error setting filter - %s\n", pcap_geterr(handler));
            exit(1);
        }
    }
    cout<<endl;
    packet_number++;
}

int main(){
    // List all the devices
    char* selected_device = find_devices();

    // Listen on a particular device
    open_device(selected_device);
    
    // Show the info of the selected device
    if(pcap_lookupnet(selected_device, &ip, &subnet_mask, errbuf) == -1){
        fprintf(stderr, "pcap_lookupnet(): %s\n", errbuf);
        exit(1);
    }
    struct in_addr net_addr;
    net_addr.s_addr = ip;
    char* tmp_IP = inet_ntoa(net_addr);
    for(int i=0;i<11;i++){
        IP[i]=tmp_IP[i];
    }
    
    // Input the filter expression
    cout<<"Insert BPF filter expression:"<<endl;
    getline(cin, filter_exp);
    
    // Compile the filter expression and set the filter
    struct bpf_program filter;
    if (pcap_compile(handler, &filter, filter_exp.c_str(), 0, ip) == -1) {
        printf("Bad filter - %s\n", pcap_geterr(handler));
        exit(1);
    }
    if (pcap_setfilter(handler, &filter) == -1) {
        printf("Error setting filter - %s\n", pcap_geterr(handler));
        exit(1);
    }
    cout<<"filter: "<<filter_exp<<endl;

    // Process the packets
    pcap_loop(handler, 0, packet_processing, NULL);

    return 0;
}