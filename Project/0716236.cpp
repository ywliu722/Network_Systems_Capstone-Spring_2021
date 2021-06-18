#include <iostream>
#include <pcap.h>
#include <vector>
#include <string>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <cstring>
#include <cstdio>
#include <stdlib.h>

using namespace std;
pcap_t *handler;
bool bridge_stats=false;
int packet_number = 1;
char IP[11];
char errbuf[PCAP_ERRBUF_SIZE];
string filter_exp;
bpf_u_int32 subnet_mask, ip;
struct grehdr
{   
    u_int16_t op;
    u_int16_t ether_type;
    u_int32_t key;
};

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
    struct udphdr *udph;
    struct grehdr *greh;
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
        if((int)iph->ip_p == 17){
            printf("Next Layer Protocol:  UDP\n\n");
        }
        packet+=sizeof(struct ip);
    }
    // UDP header
    udph = (struct udphdr *)packet;
    int sport = (int)ntohs(udph->source);
    int dport = (int)ntohs(udph->dest);
    printf("UDP Src port:  %d\n", sport);
    printf("UDP Dst port:  %d\n\n", dport);
    packet+=sizeof(struct udphdr);

    // GRE header
    greh = (struct grehdr *)packet;
    int gre_proto = (int)ntohs(greh->ether_type);
    int gre_key = (int)ntohl(greh->key);
    if(gre_proto != 0x6558){
        printf("Not GRE packet!\n\n");
        packet_number++;
        return;
    }
    printf("Protocol type: 0x%X\n", gre_proto);
    printf("GRE Key: %d\n\n", gre_key);
    packet+=sizeof(struct grehdr);
    
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
        char command1[100], command2[200], command3[50], command4[50], src_port[6];
        char* tmp_IP = inet_ntoa(iph->ip_src);
        for(int i=0;i<strlen(tmp_IP);i++){
            srcIP+=tmp_IP[i];
        }
        tmp_IP = inet_ntoa(iph->ip_dst);
        for(int i=0;i<strlen(tmp_IP);i++){
            dstIP+=tmp_IP[i];
        }
        sprintf(command1, "ip fou add port %d ipproto 47", dport);
        //printf("%s\n",command1);
        system(command1);
        sprintf(command2, "ip link add GRE%d type gretap remote %s local %s key %d encap fou encap-sport %d encap-dport %d", packet_number, srcIP.c_str(), dstIP.c_str(), gre_key, dport, sport);
        //printf("%s\n",command2);
        system(command2);
        sprintf(command3, "ip link set GRE%d up", packet_number);
        //printf("%s\n",command3);
        system(command3);
        if(!bridge_stats){
            system("ip link add br0 type bridge");
            system("brctl addif br0 BRGr-eth0");
        }
        sprintf(command4, "brctl addif br0 GRE%d", packet_number);
        //printf("%s\n",command4);
        system(command4);
        if(!bridge_stats){
            system("ip link set br0 up");
        }
        bridge_stats = true;

        // Update filter expression
        sprintf(src_port, "%d", sport);
        string port = string(src_port);
        filter_exp += " && port not "+port;
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