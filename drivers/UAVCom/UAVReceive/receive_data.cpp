#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "udp.h"
#include "jpeg_decompress.h"
#include "imgproc.h"

#define UDP_HOST "127.0.0.1"
#define UDP_PORT 12345

int main(int argc, char **argv)
{
        UdpConnectReceive(UDP_HOST, UDP_PORT);
        
        std::list<UdpPacket> udp_packets;
        uint8_t *image = NULL;
        int width, height, channels;
        struct timespec ts1, ts2;
        uint32_t count = 0;
        double dt_acc = 0;
	printf("connected!\n"); 
        while(1)
                {
                        UdpReceiveGetPackets(udp_packets);
                        if (udp_packets.begin()==udp_packets.end())
                                printf("no packets received\n");
                      
                        for(std::list<UdpPacket>::iterator it = udp_packets.begin(); it != udp_packets.end(); it++)
                                {
                                        count++;
                                        clock_gettime(CLOCK_MONOTONIC, &ts2);
                                        double dt = (ts2.tv_sec - ts1.tv_sec)*1000 + (ts2.tv_nsec - ts1.tv_nsec)/1e6;
                                        dt_acc += dt;
                                        printf("dt: %f ms\n", dt);
                                        clock_gettime(CLOCK_MONOTONIC, &ts1);
//parse imu data
//decompress image data
                                        jpeg_decompress(&(it->data[12*4]), it->data.size(), &image, &width, &height, &channels);
//printf("width: %d, height: %d\n", width, height);
#if 1
                                        if(channels == 1)
                                                imgproc(image, width, height);
                                        else
                                                printf("Expecting monochrome image, got image with channels = %d\n", channels);
#endif
                                        int N = 10;
                                        if(count % N == 0)
                                                {
                                                        //printf("dt: %f ms\n", dt_acc/N);
                                                        count = 0;
                                                        dt_acc = 0;
                                                }
                                        printf("received packet\n");
                                }
                        usleep(1000);
                }
        return 0;
}
