#include "SerialDevice.hh"
#include <stdint.h>
#include <vector>
#include <string>
#include "XbeeFrame.h"

#define XBEE_MAX_DATA_LENGTH 128
#define XBEE_API_PACKET_OVERHEAD_BYTES 9 
#define XBEE_API_START_DELIMETER 0x7E
#define XBEE_API_TX_REQUEST_16 0x01
#define XBEE_API_RX_PACKET_16 0x81

using namespace std;

namespace Upenn
{
  class Xbee
  {
    public: Xbee();
    public: ~Xbee();


    public: int Connect(string dev, int baud);
    public: int Disconnect();
    public: int WritePacket(uint8_t * data, int size);
    public: int ReceivePacket(XbeeFrame * frame,double timeout);

    private: SerialDevice sd;
    private: bool connected;

  };
}
