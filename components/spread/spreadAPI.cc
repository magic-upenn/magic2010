/*
   status = spreadAPI(args);

   Matlab Unix MEX file
   to interface to Spread 4 API.

   Compile with:
   mex -O spreadAPI.cc -I/usr/local/include /usr/local/lib/libspread.a

   Daniel D. Lee, 12/06, rev. 6/10
   <ddlee@seas.upenn.edu>
*/

#include <stdlib.h>
#include <string.h>

#include "mex.h"
#include "sp.h"

typedef unsigned char uint8;
typedef unsigned short uint16;

const int MAX_GROUPS = 4;
const int MAX_MESS_LENGTH = 102400;

static mailbox mbox = -1;
static char recv_mess[MAX_MESS_LENGTH];


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int buflen = 256;
  char buf[buflen];
  int ret = 0;

  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  if (mxGetString(prhs[0], buf, buflen) != 0) 
    mexErrMsgTxt("Could not read string.");

  if (strcmp(buf, "connect") == 0) {
    char spread_name[MAX_PROC_NAME];
    if ((nrhs < 2) || (mxGetString(prhs[1], spread_name, sizeof(spread_name)) != 0))
      mexErrMsgTxt("Could not read spread name.");

    char *private_name = NULL;
    if ((nrhs >= 3) && !mxIsEmpty(prhs[2])) {
      if (mxGetString(prhs[2], buf, MAX_PRIVATE_NAME) != 0)
	mexErrMsgTxt("Could not read private name.");
      private_name = buf;
    }

    int priority = 0;
    if ((nrhs >= 4) && !mxIsEmpty(prhs[3])) {
      priority = (int) mxGetScalar(prhs[3]);
    }

    int group_membership = 1;
    if ((nrhs >= 5) && !mxIsEmpty(prhs[4])) {
      group_membership = (int) mxGetScalar(prhs[4]);
    }

    char private_group[MAX_GROUP_NAME];

    ret = SP_connect(spread_name, private_name, priority, group_membership,
		       &mbox, private_group);
    if (ret != ACCEPT_SESSION) {
      mexErrMsgTxt("Could not connect to spread.");
    }

    plhs[0] = mxCreateDoubleScalar((double) mbox);
    if (nlhs > 1) {
      plhs[1] = mxCreateString(private_group);
    }
    return;
  }

  else if (strcmp(buf, "disconnect") == 0) {
    ret = SP_disconnect(mbox);
  }

  else if (strcmp(buf, "kill") == 0) {
    SP_kill(mbox);
  }

  else if (strcmp(buf, "join") == 0) {
    if ((nrhs < 2) || (mxGetString(prhs[1], buf, MAX_GROUP_NAME) != 0))
      mexErrMsgTxt("Could not read group name.");

    ret = SP_join(mbox, buf);
  }

  else if (strcmp(buf, "leave") == 0) {
    if ((nrhs < 2) || (mxGetString(prhs[1], buf, MAX_GROUP_NAME) != 0))
      mexErrMsgTxt("Could not read group name.");

    ret = SP_leave(mbox, buf);
  }

  else if (strcmp(buf, "multicast") == 0) {
    if (nrhs < 5) {
      mexErrMsgTxt("Need service type, group, message type, message");
    }

    service service_type = (service) mxGetScalar(prhs[1]);
    char group[MAX_GROUP_NAME];
    if ((mxGetString(prhs[2], group, sizeof(group)) != 0))
      mexErrMsgTxt("Could not read group.");
    int16 mess_type = (int16) mxGetScalar(prhs[3]);

    char *sendbuf = (char *) mxGetData(prhs[4]);
    unsigned int nsend = mxGetNumberOfElements(prhs[4])*
      mxGetElementSize(prhs[4]);

    ret = SP_multicast(mbox, service_type, group, mess_type, nsend, sendbuf);
    if (ret < 0) {
      SP_error(ret);
      mexErrMsgTxt("Unable to send Spread multicast");
    }
  }

  else if (strcmp(buf, "receive") == 0) {
    char sender[MAX_GROUP_NAME];
    char groups[MAX_GROUPS][MAX_GROUP_NAME];
    int num_groups;
    membership_info memb_info;
    service service_type = 0;
    int16 mess_type = 0;
    int endian_mismatch = 0;

    // Optional argument to set DROP_RECV
    if (nrhs >= 2) {
      service_type = (service) mxGetScalar(prhs[1]);
    }

  
    ret = SP_receive(mbox, &service_type, sender,
		     MAX_GROUPS, &num_groups, groups,
		     &mess_type, &endian_mismatch,
		     sizeof(recv_mess), recv_mess);

    if (ret >= 0) {
      const char *fields[] = {
	"service_type", "sender", "groups", "endian_mismatch",
	"message_type", "message"
      };
      const int nfields = sizeof(fields)/sizeof(*fields);

      plhs[0] = mxCreateStructMatrix(1, 1, nfields, fields);

      mxSetField(plhs[0], 0, "service_type",
		 mxCreateDoubleScalar((double) service_type));
      mxSetField(plhs[0], 0, "message_type",
		 mxCreateDoubleScalar((double) mess_type));
      mxSetField(plhs[0], 0, "endian_mismatch",
		 mxCreateDoubleScalar((double) endian_mismatch));
      mxSetField(plhs[0], 0, "sender",
		 mxCreateString(sender));

      const char *groups_ptr[MAX_GROUPS];
      for (int i = 0; i < num_groups; i++) groups_ptr[i] = groups[i];
      mxSetField(plhs[0], 0, "groups",
		 mxCreateCharMatrixFromStrings(num_groups, groups_ptr));

      int dims[2];
      dims[0] = 1;
      dims[1] = ret;
      mxArray* messArray = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
      memcpy((uint8 *)mxGetData(messArray), recv_mess, ret);
      
      mxSetField(plhs[0], 0, "message", messArray);
      return;
    } else {
      SP_error(ret);
      mexErrMsgTxt("Unable to receive Spread message");
    }
  }

  else if (strcmp(buf, "poll") == 0) {
    ret = SP_poll(mbox);
  }

  else if (strcmp(buf, "version") == 0) {
    int major, minor, patch;
    SP_version(&major, &minor, &patch);
    plhs[0] = mxCreateDoubleMatrix(1, 3, mxREAL);
    double *x = mxGetPr(plhs[0]);
    x[0] = major;
    x[1] = minor;
    x[2] = patch;
    return;
  }

  else if (strcmp(buf, "set_mailbox") == 0) {
    mbox = (mailbox) mxGetScalar(prhs[1]);
  }

  else {
    mexErrMsgTxt("Unknown option");
  }

  // Return default output:
  plhs[0] = mxCreateDoubleScalar((double) ret);

}
