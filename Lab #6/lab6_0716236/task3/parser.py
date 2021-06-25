import dpkt
import datetime
import socket
import sys
import math

# global variable
handoff = 0
sum_rate = 0.0
ap_list = []

class ap():
    def __init__(self):
        self.ap_addr=''
        self.duration=0.0
        self.transmit=0

def get_formatted_mac_addr(original_mac_addr):
    return ':'.join('%02x' % dpkt.compat.compat_ord(x) for x in original_mac_addr)

def print_packets(pcap):
    '''
    [TODO]: 
    1. Use MGMT_TYPE packets to calculate AP's mac addr / connection time / handoff times, and to collect beacon SNR
    2. Use DATA_TYPE packets to calculate total transmitted bytes / CDF of packets' SNR 
    3. Please do not print the SNR information in your submitted code, dump it to a file instead
    Note: As for SNR information, you only need to count downlink packets (but for all APs)
    '''
    # Declare variables that would use later
    global handoff
    global sum_rate
    isAssociated = False
    previous_ap = ''
    station = ''
    association_stamp = 0.0
    data_SNR = []
    current_ap = ap()

    # For each packet in the pcap process the contents
    for timestamp, buf in pcap:
        # radiotap -> ieee80211
        wlan_pkt = dpkt.radiotap.Radiotap(buf).data
        
        # if the current packet is management packet
        if(wlan_pkt.type == dpkt.ieee80211.MGMT_TYPE): 
            # Beacon packet
            if wlan_pkt.subtype == dpkt.ieee80211.M_BEACON:
                if get_formatted_mac_addr(wlan_pkt.mgmt.bssid) == current_ap.ap_addr:
                    snr = dpkt.radiotap.Radiotap(buf).ant_sig.db - dpkt.radiotap.Radiotap(buf).ant_noise.db
                    sum_rate += (0.1024/60) * 20 * math.log2(1+ math.pow(10, snr/10))
            # Disassociation packet (This is for threshold-based handoff algorithm to determine whether it is disassociated or not)
            elif wlan_pkt.subtype == dpkt.ieee80211.M_DISASSOC:
                isAssociated = False
                wasAssociated = False
                previous_ap = current_ap.ap_addr
                for connected in ap_list:
                    if connected.ap_addr == current_ap.ap_addr:
                        wasAssociated = True
                        connected.duration += (timestamp - association_stamp)
                        connected.transmit += current_ap.transmit
                if wasAssociated == False:
                    disassociation_ap = ap()
                    disassociation_ap.ap_addr = current_ap.ap_addr
                    disassociation_ap.duration = timestamp - association_stamp
                    disassociation_ap.transmit = current_ap.transmit
                    ap_list.append(disassociation_ap)
                current_ap.transmit = 0
                current_ap.ap_addr = ''
            # Association Response
            elif wlan_pkt.subtype == dpkt.ieee80211.M_ASSOC_RESP:
                isAssociated = True
                if previous_ap != get_formatted_mac_addr(wlan_pkt.mgmt.bssid) and previous_ap != '':
                    handoff += 1
                current_ap.ap_addr = get_formatted_mac_addr(wlan_pkt.mgmt.bssid)
                station = get_formatted_mac_addr(wlan_pkt.mgmt.dst)
                association_stamp = timestamp

            # Probing Request (This is for origin handoff algorithm to determine whether it is disassociated or not)
            elif wlan_pkt.subtype == dpkt.ieee80211.M_PROBE_REQ:
                if isAssociated == True:
                    isAssociated = False
                    wasAssociated = False
                    previous_ap = current_ap.ap_addr
                    for connected in ap_list:
                        if connected.ap_addr == current_ap.ap_addr:
                            wasAssociated = True
                            connected.duration += (timestamp - association_stamp)
                            connected.transmit += current_ap.transmit
                    if wasAssociated == False:
                        disassociation_ap = ap()
                        disassociation_ap.ap_addr = current_ap.ap_addr
                        disassociation_ap.duration = timestamp - association_stamp
                        disassociation_ap.transmit = current_ap.transmit
                        ap_list.append(disassociation_ap)
                    current_ap.transmit = 0
                    current_ap.ap_addr = ''
        
        # if the current packet is data packet
        elif(wlan_pkt.type == dpkt.ieee80211.DATA_TYPE):
            # ieee80211 -> llc
            llc_pkt = dpkt.llc.LLC(wlan_pkt.data_frame.data)
            if llc_pkt.type == dpkt.ethernet.ETH_TYPE_IP:
                if get_formatted_mac_addr(wlan_pkt.data_frame.bssid) == current_ap.ap_addr:
                    # llc -> ip -> udp
                    udp_pkt = (llc_pkt.data).data
                    current_ap.transmit += udp_pkt.ulen
                if get_formatted_mac_addr(wlan_pkt.data_frame.dst) == station:
                    snr = dpkt.radiotap.Radiotap(buf).ant_sig.db - dpkt.radiotap.Radiotap(buf).ant_noise.db
                    data_SNR.append(snr)
    
    # if the station is still associated before the simulation is done
    if isAssociated == True:
        wasAssociated = False
        for connected in ap_list:
            if connected.ap_addr == current_ap.ap_addr:
                wasAssociated = True
                connected.duration += (60 - association_stamp)
                connected.transmit += current_ap.transmit
        if wasAssociated == False:
            disassociation_ap = ap()
            disassociation_ap.ap_addr = current_ap.ap_addr
            disassociation_ap.duration = 60 - association_stamp
            disassociation_ap.transmit = current_ap.transmit
            ap_list.append(disassociation_ap)
    '''
    # Output downlink data packet SNR to text file
    with open("result", "w") as text_file:
        text_file.write('[')
        for i in range(len(data_SNR)):
            if i != 0:
                text_file.write(', ')
            text_file.write(str(data_SNR[i]))
        text_file.write(']')
        text_file.write('\nSum rate: %f' %sum_rate)
        text_file.write('\nHandoff: %d' %handoff)
        total_duration = 0.0
        for connect_ap in ap_list:
            total_duration += connect_ap.duration
        text_file.write('\nTotal duration: %f' %total_duration)
    text_file.close()
    '''

if __name__ == '__main__':
    with open(sys.argv[1], 'rb') as f:
        pcap = dpkt.pcap.Reader(f)
        print_packets(pcap)
    
    print('[Connection statistics]')
    for i in range(len(ap_list)):
        print('- AP%d' %(i+1))
        print('  - Mac addr: %s' %ap_list[i].ap_addr)
        print('  - Total connection duration: %.4fs' % ap_list[i].duration)
        print('  - Total transmitted bytes: %d bytes' % ap_list[i].transmit)
    print('\n[Other statistics]')
    print('  - Number of handoff events: %d' % handoff)
    print('  - Theoretical sum-rate: %d mbps' % int(math.floor(sum_rate)))