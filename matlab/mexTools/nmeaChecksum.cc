#include <mex.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

//From driver_nmea.c found in gpsd
short nmea_checksum(char *sentence, unsigned char *correct_sum)
/* is the checksum on the specified sentence good? */
{
    unsigned char sum = '\0';
    char c, *p = sentence, csum[3];
    if (*p == '$')
      p++;

    while ((c = *p++) != '*' && c != '\0')
    {
      sum ^= c;
      //printf("%c",c); fflush(stdout);
    }
    if (correct_sum)
      *correct_sum = sum;
    (void)snprintf(csum, sizeof(csum), "%02X", sum);
    //printf("\n checksum = %s \n",csum); fflush(stdout);
    return(csum[0]==toupper(p[0])) && (csum[1]==toupper(p[1]));
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Get input arguments
  if (nrhs == 0) 
  {
    mexErrMsgTxt("Need input argument");
  }

  const int BUFLEN = 256;
  char str[BUFLEN];

  if (mxGetString(prhs[0], str, BUFLEN) != 0)
  {
    mexErrMsgTxt("uavAPI: Could not read string.");
  }

  unsigned char correctSum;
  int ret = nmea_checksum(str,&correctSum);
  if (ret != 1)
    printf("Checksum error! Correct sum should be %02X\n",correctSum);
  plhs[0] = mxCreateDoubleScalar(ret);
}



