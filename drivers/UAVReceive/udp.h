#ifndef UDP_H
#define UDP_H

#include <stdint.h>
#include <string.h>
#include <string>
#include <vector>
#include <list>
#include "Timer.hh"

class UdpPacket
{
 public:
  UdpPacket() {}
  UdpPacket(std::string _srcAddr, int _srcPort, uint8_t * _data, int size)
  {
    t         = Timer::GetUnixTime();
    srcAddr   = _srcAddr;
    srcPort   = _srcPort;
    data.resize(size);
    memcpy(&(data[0]),_data,size);
  }
  string srcAddr;
  int srcPort;
  std::vector<uint8_t> data;
  double t;
};

int UdpConnectSend(const char * address, int port);
int UdpConnectReceive(const char * address, int port);
int UdpDisconnectReceive();

int UdpSend(uint8_t * data, int size);
int UdpReceive(uint8_t * data, int * size);
int UdpReceiveGetPackets(std::list<UdpPacket> & packets_out);

#endif
