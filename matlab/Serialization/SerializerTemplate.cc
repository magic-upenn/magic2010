#include <string.h>

static bool initialized = false;
static FORMATTER_PTR formatter;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int BUFLEN = 256;
  char command[BUFLEN];

  //check input arguments
  if (nrhs < 1)
    mexErrMsgTxt("Need at least one input argument");

  //initialize ipc stuff if needed
  if (!initialized)
  {
    if (IPC_initialize() != IPC_OK)
      mexErrMsgTxt("Could not initialize ipc");
      
    formatter = IPC_parseFormat(DATA_TYPE::getIPCFormat());
    initialized=true;
  }
  
  //get the command type
  if (mxGetString(prhs[0], command, BUFLEN) != 0)
    mexErrMsgTxt("Could not read string. (1st argument)");


  if (strcmp(command, "serialize") == 0)
  {
    if (nrhs != 2)
      mexErrMsgTxt("need second argument");

    DATA_TYPE data;
    int numFieldsRead = data.ReadFromMatlab((mxArray*)prhs[1],0);

    if (numFieldsRead < 1)
      mexErrMsgTxt("could not read the data structure");
      
    IPC_VARCONTENT_TYPE varcontent;

    if (IPC_marshall( formatter, &data, &varcontent) != IPC_OK)
      mexErrMsgTxt("error marshalling a message");

    CreateSerializedOutputAndFreeVarcontent(plhs,&varcontent);
  }


  else if (strcmp(command, "deserialize") == 0)
  {
    if (nrhs != 2)
      mexErrMsgTxt("need second argument");

    if (mxGetClassID(prhs[1]) != mxUINT8_CLASS)
      mexErrMsgTxt("second argument must be serialized data as uint8 type");

    DATA_TYPE data;
  
    if (IPC_unmarshallData( formatter, mxGetData(prhs[1]), (void*)&data,
    sizeof(DATA_TYPE)) != IPC_OK)
      mexErrMsgTxt("Could not unmarshall packet");
    
    DATA_TYPE::CreateMatlabStructMatrix(&(plhs[0]),1,1);
    data.WriteToMatlab(plhs[0],0);
    
    //free IPC data
    IPC_freeDataElements(formatter, &data);
  }


  else if (strcmp(command, "getFormat") == 0)
  {
    plhs[0] = mxCreateString(DATA_TYPE::getIPCFormat());
  }

  else
    mexErrMsgTxt("unknown command");

  return;
}


