#ifndef __IPCMailbox_HH__
#define __IPCMailbox_HH__

#include "ipc.h"
#include <string>
#include <iostream>
#include <sstream>
#include <vector>
#include "StandardDataTypes.hh"

using namespace std;


//parent class for the message mailboxes. Implement a child class to handle each type of messages
class IPCMailbox 
{

	public:
		IPCMailbox()
    {
			mSubscribed=false;
			mFresh=false;
			mClassName=std::string("Undefined_Mailbox");
			mMsgName=std::string("Undefined_Msg");
			mMsgHandler=NULL;
		}

		~IPCMailbox()
    {
      Unsubscribe();
		}

		int Subscribe()
    {
			//make sure that the message handler has been set
			if (mMsgHandler == NULL)
      {
#ifdef IPC_MAILBOX_DEBUG
				cout<<mClassName<<":: Subscribe: ERROR: message handler is not defined!!"<<endl;
#endif
				return -1;
			}

      if (mSubscribed == true)
      {
#ifdef IPC_MAILBOX_DEBUG
        cout<<mClassName<<":: Subscribe: Warning: already subscribed to a message of type "<<mMsgName<<endl;
#endif
        return 0;
      }

			//subscribe to the message type and provide a pointer to this exact instance,
			//so that its internal data can be updated by the message handler function
			if (IPC_subscribe(mMsgName.c_str(),mMsgHandler,(void *)(this)) != IPC_OK)
      {
#ifdef IPC_MAILBOX_DEBUG
				cout<<mClassName<<":: Subscribe: ERROR: could not subscribe to a message of type "<<mMsgName<<endl;
#endif
				return -1;
			}
			mSubscribed=true;
#ifdef IPC_MAILBOX_DEBUG
      cout<<mClassName<<":: Subscribe: Subscribed to a message of type "<<mMsgName<<endl;
#endif
			return 0;
		}

    int Unsubscribe()
    {
      if (IPC_unsubscribe(mMsgName.c_str(),mMsgHandler) == IPC_OK)
      {
#ifdef IPC_MAILBOX_DEBUG
      cout<<mClassName<<":: Unsubscribe: Unsubscribed from a message of type "<<mMsgName<<endl;
#endif
      }
      else
      {
#ifdef IPC_MAILBOX_DEBUG
      cout<<mClassName<<":: Unsubscribe: ERROR: Could not unsubscribe from a message of type "<<mMsgName<<endl;
#endif
      }
      mSubscribed = false;
      return 0;
    }

		//checks whether there is fresh data (that has not been read yet)
		inline bool IsFresh() { return mFresh; }

    //child class needs to implement this function
    virtual void * GetData() = 0;

	protected:

		bool mSubscribed;
		bool mFresh;
		string mClassName;			//class name
		string mMsgName;				//official message name
    string mId;              //id of the client
		HANDLER_TYPE mMsgHandler;		//function that handles the messages
};



class PoseMailbox : public IPCMailbox 
{
	public:
		PoseMailbox(const char * id, const char * msg_suffix)
    {
			mClassName=string("PoseMailbox") + string("(") + string(id) + string(")");
			mMsgName=string(id) + string(msg_suffix);
			mMsgHandler=msgHandler;
      mId=string(id);
			mPose=new RobotPose();		//stores the latest robot pose
		}

		//cleanup
		~PoseMailbox()
    {
			delete mPose;
		}
	
		//returns a pointer to the latest pose and marks it "not fresh"
		virtual void * GetData()
    {
			mFresh=false;
			return mPose;
		}

	protected:

		//function handle for the message. It simply fills in the data into the members of this class
		void static msgHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData)
    {
			//cast the pointer as pose mailbox
			PoseMailbox * mailbox = (PoseMailbox *)clientData;
			
			//copy the data into the mailbox			
			memcpy(mailbox->mPose,callData,sizeof(RobotPose));
			
			//reset the "fresh flag"			
			mailbox->mFresh=true;
			
			//free the IPC data			
			IPC_freeByteArray(callData);
#ifdef IPC_MAILBOX_DEBUG
			cout<<mailbox->mClassName<<":: Received a message : "<<mailbox->mMsgName<<endl;
#endif
		}
		
		RobotPose * mPose;	//points to the latest data
};

typedef XYZ TRAJ_TYPE;

class TrajMailbox : public IPCMailbox {
	public:
		TrajMailbox(const char * id, const char * msg_suffix){
			mClassName=string("TrajMailbox") + string("(") + string(id) + string(")");
			mMsgName=string(id) + string(msg_suffix);
			mMsgHandler=msgHandler;
			mTraj=new std::vector<TRAJ_TYPE>;		//stores the latest trajectory
		}

		//cleanup
		~TrajMailbox(){
			delete mTraj;
		}
	
		//returns a pointer to the latest traj and marks it "not fresh"
		virtual void * GetData(){
			mFresh=false;
			return mTraj;
		}

	protected:

		//function handle for the message. It simply fills in the data into the members of this class
		void static msgHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData){
			//cast the pointer as pose mailbox
			TrajMailbox * mailbox = (TrajMailbox *)clientData;
			
			double * data = (double *)(callData);
			int nPoints=(int)data[0];
			
			//purge the current trajectory
			mailbox->mTraj->clear();
	
			//parse the new trajectory
			for (int i=0; i< nPoints; i++){
				TRAJ_TYPE point;
				memcpy(&point,&(data[sizeof(TRAJ_TYPE)/sizeof(double)*i+1]),sizeof(TRAJ_TYPE));
				mailbox->mTraj->push_back(point);
			}
			
			//reset the "fresh flag"			
			mailbox->mFresh=true;
			
			//free the IPC data			
			IPC_freeByteArray(callData);
#ifdef MAILBOX_DEBUG
			std::cout<<mailbox->mClassName<<":: Received a message : "<<mailbox->mMsgName<<std::endl;
#endif
		}
		
		std::vector<TRAJ_TYPE> * mTraj;		//points to the latest traj
};


struct LASER_DATA_INFO
{
  LASER_DATA_INFO(): n_points(0), angles(NULL), ranges(NULL), intensity(NULL){}
  LASER_DATA_INFO(unsigned int _n_points, double * _angles, double * _ranges, double * _intensity) :
    n_points(_n_points),angles(_angles), ranges(_ranges), intensity(_intensity){}
  unsigned int n_points;
  double * angles;
  double * ranges;
  double * intensity;
};

class LaserMailbox : public IPCMailbox {
	public:
		LaserMailbox(const char * id, const char * msg_suffix){
			mClassName=string("LaserMailbox") + string("(") + string(id) + string(")");
			mMsgName=string(id) + string(msg_suffix);
			mMsgHandler=msgHandler;
      n_points=0;
      angles = NULL;
      ranges = NULL;
      intensity = NULL;
      laser_data = new LASER_DATA_INFO(0,angles, ranges, intensity);
		}

		//cleanup
		~LaserMailbox(){
      delete laser_data;
      ClearData();
		}
	
		//returns a pointer to the latest traj and marks it "not fresh"
		virtual void * GetData(){
			mFresh=false;
			return laser_data;
		}

	protected:

    void ClearData()
    {
      if (angles != NULL)
        delete [] angles;

      if (ranges != NULL)
        delete [] ranges;

      if (intensity != NULL)
        delete [] intensity;
    }

		//function handle for the message. It simply fills in the data into the members of this class
		void static msgHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData){
			//cast the pointer as pose mailbox
			LaserMailbox * mailbox = (LaserMailbox *)clientData;
			
			double * data = (double *)(callData);
			mailbox->n_points=(int)data[0];

      if (mailbox->n_points < 0 )
      {
        std::cout<<mailbox->mClassName<<"::ERROR: n_points less than zero"<<std::endl;
        exit(1);
      }
			
			mailbox->ClearData();
      mailbox->angles    = new double[mailbox->n_points];
      mailbox->ranges    = new double[mailbox->n_points];
      mailbox->intensity = new double[mailbox->n_points];

      memcpy(mailbox->angles,data+1,mailbox->n_points*sizeof(double));
      memcpy(mailbox->ranges,data+1+mailbox->n_points,mailbox->n_points*sizeof(double));
      memcpy(mailbox->intensity,data+1+2*mailbox->n_points,mailbox->n_points*sizeof(double));
      
      mailbox->laser_data->n_points   = mailbox->n_points;
      mailbox->laser_data->angles     = mailbox->angles;
      mailbox->laser_data->ranges     = mailbox->ranges;
      mailbox->laser_data->intensity  = mailbox->intensity;
			
			//reset the "fresh flag"			
			mailbox->mFresh=true;
			
			//free the IPC data			
			IPC_freeByteArray(callData);
#ifdef MAILBOX_DEBUG
			std::cout<<mailbox->mClassName<<":: Received a message : "<<mailbox->mMsgName<<std::endl;
#endif
		}
		
		double * angles;
    double * ranges;
    double * intensity;
    int n_points;
    LASER_DATA_INFO * laser_data;
};

struct ByteStreamInfo
{
  ByteStreamInfo() : size(0), data(NULL) {}
  ByteStreamInfo(unsigned int _size, char * _data) : size(_size), data(_data) {}
  unsigned int size;
  char * data;
};

struct POINTS_INFO
{
  POINTS_INFO(): n_points(0), xs(NULL), ys(NULL), zs(NULL), rs(NULL), gs(NULL), bs(NULL) {}
  POINTS_INFO(unsigned int _n_points, double * _xs, double * _ys, double * _zs, double * _rs, double * _gs, double * _bs, double * _as) :
    n_points(_n_points), xs(_xs), ys(_ys), zs(_zs), rs(_rs), gs(_gs), bs(_bs), as(_as) {}
  unsigned int n_points;
  double *xs, *ys, *zs, *rs, *gs, *bs, *as;
};


class ByteStreamMailbox : public IPCMailbox {
	public:
		ByteStreamMailbox(const char * id, const char * msg_suffix){
			mClassName=string("ByteStreamMailbox") + string("(") + string(id) + string(")");
			mMsgName=string(id) + string(msg_suffix);
			mMsgHandler=msgHandler;
      buf_size = 0;
      buf = NULL;
		}

		//cleanup
		~ByteStreamMailbox(){
      if (buf != NULL)
        delete buf;
    }
	
		//returns a pointer to the latest traj and marks it "not fresh"
		virtual void * GetData(){
			mFresh=false;
			return &stream_info;
		}

    int GetLaserDataInfo(ByteStreamInfo * stream_info, LASER_DATA_INFO * laser_data_info)
    {
      double * data = (double*)stream_info->data;
      
      //check the number of points
      if (data[0] < 0)  
      {
        cout<<"GetLaserDataInfo: size less than zero"<<endl;
        exit(1);
      }

      laser_data_info->n_points = (unsigned int)data[0];

      laser_data_info->angles    = data + 1;
      laser_data_info->ranges    = data + 1 + laser_data_info->n_points;
      laser_data_info->intensity = data + 1 + 2*laser_data_info->n_points;

      return 0;
    }

    int GetPointsInfo(ByteStreamInfo * stream_info, POINTS_INFO * points_info)
    {
      double * data = (double*)stream_info->data;
      
      //check the number of points
      if (data[0] < 0)  
      {
        cout<<"GetPointsInfo: size less than zero"<<endl;
        exit(1);
      }

      points_info->n_points = (unsigned int)data[0];
      points_info->xs = data + 1;
      points_info->ys = points_info->xs + points_info->n_points;
      points_info->zs = points_info->ys + points_info->n_points;
      points_info->rs = points_info->zs + points_info->n_points;
      points_info->gs = points_info->rs + points_info->n_points;
      points_info->bs = points_info->gs + points_info->n_points;
      points_info->as = points_info->bs + points_info->n_points;

      return 0;
    }

	protected:

		//function handle for the message. It simply fills in the data into the members of this class
		void static msgHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData){
			//cast the pointer as pose mailbox
			ByteStreamMailbox * mailbox = (ByteStreamMailbox *)clientData;


      unsigned int new_buf_size = IPC_dataLength(msgRef);
      if (new_buf_size < 0 )
      {
        std::cout<<mailbox->mClassName<<"::ERROR: buffer size is less than zero"<<std::endl;
        exit(1);
      }

      //allocate memory if needed
      if (new_buf_size > mailbox->buf_size)
      {
        delete [] mailbox->buf;
        mailbox->buf = new char[new_buf_size];
      }

      //copy the contents      
      memcpy(mailbox->buf,callData,new_buf_size);
      mailbox->buf_size = new_buf_size;

      mailbox->stream_info = ByteStreamInfo(mailbox->buf_size,mailbox->buf);
			
			//reset the "fresh flag"			
			mailbox->mFresh=true;

			
			//free the IPC data			
			IPC_freeByteArray(callData);
#ifdef MAILBOX_DEBUG
			std::cout<<mailbox->mClassName<<":: Received a message : "<<mailbox->mMsgName<<std::endl;
#endif
		}
		
		unsigned int buf_size;
    char * buf;
    ByteStreamInfo stream_info;
};


#endif //__IPCMailbox_HH__
