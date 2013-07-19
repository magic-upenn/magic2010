#include "udp.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <pthread.h>
#include <signal.h>

using namespace std;

#define UDP_MAX_BUF_LEN 65500
#define DEF_MAX_QUEUE_LENGTH 50

static int fd;
static sockaddr_in addr;
static uint8_t udp_buf[UDP_MAX_BUF_LEN];

static void * UdpReceiveThreadFunc(void * input);

static bool threadRunning = false;
static size_t maxQueueLength = DEF_MAX_QUEUE_LENGTH;

pthread_t udpThread;
pthread_mutex_t udpMutex = PTHREAD_MUTEX_INITIALIZER;
list<UdpPacket> packets;
/*
 * Function to connect to a destination from the sending side
 */
int UdpConnectSend(const char * address, int port)
{
  if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
  {
    printf("could not create a socket\n");
    exit(1);
  }

  int i = 1;
  if (setsockopt(fd, SOL_SOCKET, SO_BROADCAST, (const char *) &i, sizeof(i)) < 0)
  {
    printf("Could not set broadcast option\n");
    exit(1);
  }

  memset(&addr,0,sizeof(addr));
  addr.sin_family      = AF_INET;
  addr.sin_addr.s_addr = inet_addr(address);
  addr.sin_port        = htons(port);

  return 0;
}
/*
 * Function to connect to a source from the receiving side
 */

int UdpConnectReceive(const char * address, int port)
{
  if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
  {
    printf("could not create a socket\n");
    exit(1);
  }

  sockaddr_in addr;
  memset(&addr,0,sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;

  if (strcasecmp(address,"broadcast") == 0)
    addr.sin_addr.s_addr = INADDR_ANY;
  else
    addr.sin_addr.s_addr = inet_addr(address);

  addr.sin_port=htons(port);

  if (bind(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr)) == -1)
  {
    printf("could not bind to socket\n");
    exit(1);
  }

  //start thread
  if (!threadRunning)
  {
    if (pthread_create(&udpThread,NULL,UdpReceiveThreadFunc, NULL))
    {
      printf("Could not start thread\n");
      exit(1);
    }
    threadRunning = true;
  }

  return 0;
}
 /*
 * Function to disconnect to a source from the receiving side
 */ 
int UdpDisconnectReceive()
{
  if (threadRunning)
  {
    printf("stopping udp thread..."); fflush(stdout);
    pthread_cancel(udpThread);
    pthread_join(udpThread,NULL);
    threadRunning = false;
    printf("done\n");
  }

  close(fd);

  return 0;
}

/*
 * Function to send data across a previously established link 
 */
int UdpSend(uint8_t * data, int size)
{
  if (size > UDP_MAX_BUF_LEN)
  {
    printf("data size (%d) exceeds the maximum limit of %d\n",size,UDP_MAX_BUF_LEN);
    return -1;
  }

  if (sendto(fd, data, size, 0,(struct sockaddr *) &addr, sizeof(addr)) < 0)
  {
    printf("could not send data\n");
    return -1;
  }
  return 0;
}
/*
 * Function to receive data across a previously established link 
 */

int UdpReceive(uint8_t * data, int * size)
{
  int numbytes;
  sockaddr_in senderAddr;
  socklen_t addr_len = sizeof(struct sockaddr);

  if ((numbytes = recvfrom(fd, data, UDP_MAX_BUF_LEN-1 , 0,
    (struct sockaddr *)&senderAddr, &addr_len)) == -1)
  {
    printf("error while receiving data\n");
    return -1;
  }

  *size = numbytes;

  return 0;
}

static void * UdpReceiveThreadFunc(void * input)
{
  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  while(1)
  {
    pthread_testcancel();
    int numbytes;
    sockaddr_in senderAddr;
    socklen_t addr_len = sizeof(struct sockaddr);

    if ((numbytes = recvfrom(fd, udp_buf, UDP_MAX_BUF_LEN-1 , 0,
      (struct sockaddr *)&senderAddr, &addr_len)) == -1)
    {
      printf("error while receiving data\n");
      continue;
    }

    //printf("got packet from %s\n",inet_ntoa(senderAddr.sin_addr));
    //printf("packet is %d bytes long\n",numbytes);

    pthread_mutex_lock(&udpMutex);
    packets.push_back(UdpPacket(inet_ntoa(senderAddr.sin_addr),
                                ntohs(senderAddr.sin_port),
                                 (uint8_t*)udp_buf,numbytes));

    while (packets.size() > maxQueueLength)
      packets.pop_front();
    pthread_mutex_unlock(&udpMutex);
  }

  return NULL;
}
/*
 * Function to receive multiple packets 
 */
int UdpReceiveGetPackets(list<UdpPacket> & packets_out)
{
  packets_out.clear();
  pthread_mutex_lock(&udpMutex);
  packets_out = packets;
  packets.clear();
  pthread_mutex_unlock(&udpMutex);
  return packets_out.size();
}

