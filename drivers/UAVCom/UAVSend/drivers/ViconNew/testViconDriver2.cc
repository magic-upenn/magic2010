/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "ViconDriver2.hh"
#include <stdio.h>

int main()
{ 
  ViconDriver2 vd;
  
  if ( vd.Connect("alkaline"))
  {
    printf("could not connect\n");
    return -1;
  }
  
  int cntr = 0;
  
  while(1)
  {
    usleep(10000);
    cntr++;
    
    if (cntr == 300)
      break;
  }

  return 0;
}
