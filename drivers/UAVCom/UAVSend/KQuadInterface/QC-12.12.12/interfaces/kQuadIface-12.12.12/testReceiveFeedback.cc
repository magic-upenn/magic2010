/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "kQuadInterface.hh"
#include "Timer.hh"

int verbose = 1;

int main()
{
  char * dev = (char*)"/dev/ttyUSB0";
  //int baud = 115200;
  int baud   = 921600;
  //int baud   = 1000000;
  kQuadInterface kqi;
  
  if (kqi.Connect(dev,baud))
  {
    printf("could not connect to the device\n");
    return -1;
  }
  
  if (kqi.StartSendThread())
  {
    printf("could not start send thread\n");
    return -1;
  }
  
  if (kqi.StartRecvThread())
  {
    printf("could not start receive thread\n");
    return -1;
  }
      
  list<ImuFiltData>     ifdata;
  list<ImuRawData>      irdata;
  list<BatteryData>     bdata;
  list<RcData>          rcdata;
  list<GpsNmeaData>     gpsndata;
  list<GpsUbloxData>    gpsudata;
  list<QuadStatusData>  qdata;
  list<ServoData>       sdata;
  list<PressureMagData> pmdata;
  list<ZigBeeRxStatus>  zrxdata;
  list<MotorStatusData> mdata;
  
  uint32_t nimur = 0, nimu = 0, nrc = 0, nstat = 0, npress = 0, nzrx = 0, nmotors = 0, ngpsn = 0;
  
  Timer t0; t0.Tic();
  
  int nmsg = 0;
  printf("Selected baudrate %i\n",baud);
  
  while(1)
  {    
    usleep(1000);
    double dt = t0.Toc();
    
    nmsg = kqi.GetImuRawData(irdata);
    //kqi.PrintImuRawData(irdata);
    if (nmsg > 0) nimur += nmsg;
    
    nmsg  = kqi.GetImuFiltData(ifdata); 
    if (verbose) kqi.PrintImuFiltData(ifdata);
    if (nmsg > 0) nimu += nmsg;
    
    nmsg  = kqi.GetRcData(rcdata);
    if (verbose) kqi.PrintRcData(rcdata);
    if (nmsg > 0) nrc  += nmsg;
    
    nmsg  = kqi.GetQuadStatusData(qdata);
    if (verbose) kqi.PrintQuadStatusData(qdata);
    if (nmsg > 0) nstat += nmsg;
    
    nmsg  = kqi.GetPressMagData(pmdata);
    if (verbose) kqi.PrintPressMagData(pmdata);
    if (nmsg > 0) npress += nmsg;
    
    nmsg  = kqi.GetZigRxStatData(zrxdata);
    if (verbose) kqi.PrintZigRxStatData(zrxdata);
    if (nmsg > 0) nzrx  += nmsg;
    
    nmsg  = kqi.GetMotorStatusData(mdata);
    if (verbose) kqi.PrintMotorStatusData(mdata);
    if (nmsg > 0) nmotors  += nmsg;
    
    nmsg = kqi.GetGpsNmeaData(gpsndata);
    if (verbose) kqi.PrintGpsNmeaData(gpsndata);
    if (nmsg > 0) ngpsn  += nmsg;
    
    
    if (dt > 1)
    {
      printf("----------------------------------------\n");
      printf("received : imur (%d), imu(%d), rc(%d), status(%d), press(%d), zrx(%d), motors(%d), gpsn(%d)\n",
             nimur, nimu, nrc, nstat, npress, nzrx, nmotors, ngpsn);
      
      nimur = nimu = nrc = nstat = npress = nzrx = nmotors = ngpsn = 0;
      
      t0.Tic(); 
    }
  }
  
  return 0;
}
