/*
 * Copyright (c) 2008, Maxim Likhachev
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of Pennsylvania nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef __ENVIRONMENT_MAGICLAT_H_
#define __ENVIRONMENT_MAGICLAT_H_


//eight-connected grid
#define MAGICLAT_DXYWIDTH 8

#define ENVMAGICLAT_DEFAULTOBSTHRESH 254	//see explanation of the value below

#define SBPL_MAGICLAT_MAXSTATESFORLOOKUP 100000000 //maximum number of states for storing them into lookup (as opposed to hash)

//definition of theta orientations
//0 - is aligned with X-axis in the positive direction (1,0 in polar coordinates)
//theta increases as we go counterclockwise
//number of theta values - should be power of 2
#define MAGICLAT_THETADIRS 16

//number of actions per x,y,theta state
#define MAGICLAT_DEFAULT_ACTIONWIDTH 5 //decrease, increase, same angle while moving plus decrease, increase angle while standing.

#define MAGICLAT_COSTMULT_MTOMM 1000

typedef struct{
	double x;
	double y;
} EnvMAGICLAT2Dpt_t;

typedef struct{
	double x;
	double y;
	double theta;
} EnvMAGICLAT3Dpt_t;


typedef struct EnvMAGICLAT3DCELL{
	int x;
	int y;
	int theta;
	int iteration;
public:
	bool operator == (EnvMAGICLAT3DCELL cell) {return (x==cell.x && y==cell.y && theta==cell.theta);}
} EnvMAGICLAT3Dcell_t;


typedef struct
{
	char starttheta;
	char dX;
	char dY;
	char endtheta;
	unsigned int cost; 
	vector<sbpl_2Dcell_t> intersectingcellsV;
	//start at 0,0,starttheta and end at endcell in continuous domain with half-bin less to account for 0,0 start
	vector<EnvMAGICLAT3Dpt_t> intermptV;
	//start at 0,0,starttheta and end at endcell in discrete domain
	vector<EnvMAGICLAT3Dcell_t> interm3DcellsV;
} EnvMAGICLATAction_t;


typedef struct 
{
	int stateID;
	int X;
	int Y;
	char Theta;
	int iteration;
} EnvMAGICLATHashEntry_t;


typedef struct
{
	int motprimID;
	unsigned char starttheta_c;
	int additionalactioncostmult;
	EnvMAGICLAT3Dcell_t endcell;
	//intermptV start at 0,0,starttheta and end at endcell in continuous domain with half-bin less to account for 0,0 start
	vector<EnvMAGICLAT3Dpt_t> intermptV; 
}SBPL_magic_mprimitive;


//variables that dynamically change (e.g., array of states, ...)
typedef struct
{

	int startstateid;
	int goalstateid;

	bool bInitialized;

	//any additional variables


}EnvironmentMAGICLAT_t;

//configuration parameters
typedef struct ENV_MAGICLAT_CONFIG
{
	int EnvWidth_c;
	int EnvHeight_c;
	int StartX_c;
	int StartY_c;
	int StartTheta;
	int EndX_c;
	int EndY_c;
	int EndTheta;
	unsigned char** Grid2D;

	//the value at which and above which cells are obstacles in the maps sent from outside
	//the default is defined above
	unsigned char obsthresh; 

	//the value at which and above which until obsthresh (not including it) cells have the nearest obstacle at distance smaller than or equal to 
	//the inner circle of the robot. In other words, the robot is definitely colliding with the obstacle, independently of its orientation
	//if no such cost is known, then it should be set to obsthresh (if center of the robot collides with obstacle, then the whole robot collides with it
	//independently of its rotation)
	unsigned char cost_inscribed_thresh; 

	//the value at which and above which until cost_inscribed_thresh (not including it) cells 
	//**may** have a nearest osbtacle within the distance that is in between the robot inner circle and the robot outer circle
	//any cost below this value means that the robot will NOT collide with any obstacle, independently of its orientation
	//if no such cost is known, then it should be set to 0 or -1 (then no cell cost will lower than it, and therefore the robot's footprint will always be checked)
	int cost_possibly_circumscribed_thresh; //it has to be integer, because -1 means that it is not provided.

	double nominalvel_mpersecs;
	double timetoturn45degsinplace_secs;
	double cellsize_m;

	int dXY[MAGICLAT_DXYWIDTH][2];

	EnvMAGICLATAction_t** ActionsV; //array of actions, ActionsV[i][j] - jth action for sourcetheta = i
	vector<EnvMAGICLATAction_t*>* PredActionsV; //PredActionsV[i] - vector of pointers to the actions that result in a state with theta = i

	int actionwidth; //number of motion primitives
	vector<SBPL_magic_mprimitive> mprimV;

	vector<sbpl_2Dpt_t> FootprintPolygon;
} EnvMAGICLATConfig_t;



class SBPL2DGridSearch;

class EnvironmentMAGICLATTICE : public DiscreteSpaceInformation
{

public:

	EnvironmentMAGICLATTICE();

	bool InitializeEnv(const char* sEnvFile, const vector<sbpl_2Dpt_t>& perimeterptsV, const char* sMotPrimFile);	
	bool InitializeEnv(const char* sEnvFile);
	virtual bool SetEnvParameter(const char* parameter, int value);
	virtual int GetEnvParameter(const char* parameter);
	bool InitializeMDPCfg(MDPConfig *MDPCfg);
	virtual int  GetFromToHeuristic(int FromStateID, int ToStateID) = 0;
	virtual int  GetGoalHeuristic(int stateID) = 0;
	virtual int  GetStartHeuristic(int stateID) = 0;
	virtual void SetAllActionsandAllOutcomes(CMDPSTATE* state) = 0;
	virtual void SetAllPreds(CMDPSTATE* state);
	virtual void GetSuccs(int SourceStateID, vector<int>* SuccIDV, vector<int>* CostV);
	virtual void GetPreds(int TargetStateID, vector<int>* PredIDV, vector<int>* CostV) = 0;

	virtual void EnsureHeuristicsUpdated(bool bGoalHeuristics); //see comments in environment.h


	void PrintEnv_Config(FILE* fOut);

    bool InitializeEnv(int width, int height,
		       /** if mapdata is NULL the grid is initialized to all freespace */
                       const unsigned char* mapdata,
                       double startx, double starty, double starttheta,
                       double goalx, double goaly, double goaltheta,
					   double goaltol_x, double goaltol_y, double goaltol_theta,
					   const vector<sbpl_2Dpt_t> & perimeterptsV,
					   double cellsize_m, double nominalvel_mpersecs, double timetoturn45degsinplace_secs, 
					   unsigned char obsthresh, const char* sMotPrimFile);
    bool UpdateCost(int x, int y, unsigned char newcost);
	virtual void GetPredsofChangedEdges(vector<nav2dcell_t> const * changedcellsV, vector<int> *preds_of_changededgesIDV) = 0;
	virtual void GetSuccsofChangedEdges(vector<nav2dcell_t> const * changedcellsV, vector<int> *succs_of_changededgesIDV) = 0;



	bool IsObstacle(int x, int y);
	bool IsValidConfiguration(int X, int Y, int Theta);

	void GetEnvParms(int *size_x, int *size_y, double* startx, double* starty, double* starttheta, double* goalx, double* goaly, double* goaltheta,
			double* cellsize_m, double* nominalvel_mpersecs, double* timetoturn45degsinplace_secs, unsigned char* obsthresh, vector<SBPL_magic_mprimitive>* motionprimitiveV);

	const EnvMAGICLATConfig_t* GetEnvNavConfig();


    virtual ~EnvironmentMAGICLATTICE();

    void PrintTimeStat(FILE* fOut);
  
	unsigned char GetMapCost(int x, int y);

  
  bool IsWithinMapCell(int X, int Y);
  
  /** Transform a pose into discretized form. The angle 'pth' is
      considered to be valid if it lies between -2pi and 2pi (some
      people will prefer 0<=pth<2pi, others -pi<pth<=pi, so this
      compromise should suit everyone).
      
      \note Even if this method returns false, you can still use the
      computed indices, for example to figure out how big your map
      should have been.
      
      \return true if the resulting indices lie within the grid bounds
      and the angle was valid.
  */
  bool PoseContToDisc(double px, double py, double pth,
		      int &ix, int &iy, int &ith) const;
  
  /** Transform grid indices into a continuous pose. The computed
      angle lies within 0<=pth<2pi.
      
      \note Even if this method returns false, you can still use the
      computed indices, for example to figure out poses that lie
      outside of your current map.
      
      \return true if all the indices are within grid bounds.
  */
  bool PoseDiscToCont(int ix, int iy, int ith,
		      double &px, double &py, double &pth) const;

  virtual void PrintVars(){};

 protected:

  virtual int GetActionCost(int SourceX, int SourceY, int SourceTheta, EnvMAGICLATAction_t* action);


	//member data
	EnvMAGICLATConfig_t EnvMAGICLATCfg;
	EnvironmentMAGICLAT_t EnvMAGICLAT;
	vector<EnvMAGICLAT3Dcell_t> affectedsuccstatesV; //arrays of states whose outgoing actions cross cell 0,0
	vector<EnvMAGICLAT3Dcell_t> affectedpredstatesV; //arrays of states whose incoming actions cross cell 0,0
	int iteration;

	//2D search for heuristic computations
	bool bNeedtoRecomputeStartHeuristics; //set whenever grid2Dsearchfromstart needs to be re-executed
	bool bNeedtoRecomputeGoalHeuristics; //set whenever grid2Dsearchfromgoal needs to be re-executed
	SBPL2DGridSearch* grid2Dsearchfromstart; //computes h-values that estimate distances from start x,y to all cells
	SBPL2DGridSearch* grid2Dsearchfromgoal;  //computes h-values that estimate distances to goal x,y from all cells

 	virtual void ReadConfiguration(FILE* fCfg);

	void InitializeEnvConfig(vector<SBPL_magic_mprimitive>* motionprimitiveV);


	bool CheckQuant(FILE* fOut);

	void SetConfiguration(int width, int height,
			      /** if mapdata is NULL the grid is initialized to all freespace */
			      const unsigned char* mapdata,
			      int startx, int starty, int starttheta,
			      int goalx, int goaly, int goaltheta,
				  double cellsize_m, double nominalvel_mpersecs, double timetoturn45degsinplace_secs, const vector<sbpl_2Dpt_t> & robot_perimeterV);
	
	bool InitGeneral( vector<SBPL_magic_mprimitive>* motionprimitiveV);
	void PrecomputeActionswithBaseMotionPrimitive(vector<SBPL_magic_mprimitive>* motionprimitiveV);
	void PrecomputeActionswithCompleteMotionPrimitive(vector<SBPL_magic_mprimitive>* motionprimitiveV);
	void PrecomputeActions();

	void CreateStartandGoalStates();

	virtual void InitializeEnvironment() = 0;

	void ComputeHeuristicValues();

	bool IsValidCell(int X, int Y);

	void CalculateFootprintForPose(EnvMAGICLAT3Dpt_t pose, vector<sbpl_2Dcell_t>* footprint);
	void RemoveSourceFootprint(EnvMAGICLAT3Dpt_t sourcepose, vector<sbpl_2Dcell_t>* footprint);

	virtual void GetSuccs(int SourceStateID, vector<int>* SuccIDV, vector<int>* CostV, vector<EnvMAGICLATAction_t*>* actionindV=NULL) = 0;

	double EuclideanDistance_m(int X1, int Y1, int X2, int Y2);

	void ComputeReplanningData();
	void ComputeReplanningDataforAction(EnvMAGICLATAction_t* action);

	bool ReadMotionPrimitives(FILE* fMotPrims);
	bool ReadinMotionPrimitive(SBPL_magic_mprimitive* pMotPrim, FILE* fIn);
	bool ReadinCell(EnvMAGICLAT3Dcell_t* cell, FILE* fIn);
	bool ReadinPose(EnvMAGICLAT3Dpt_t* pose, FILE* fIn);

	void PrintHeuristicValues();

};


class EnvironmentMAGICLAT : public EnvironmentMAGICLATTICE
{

 public:
  EnvironmentMAGICLAT()
  {
	HashTableSize = 0;
	Coord2StateIDHashTable = NULL;
	Coord2StateIDHashTable_lookup = NULL; 
  };

  ~EnvironmentMAGICLAT();

  int SetStart(double x, double y, double theta);
  int SetGoal(double x, double y, double theta);
  void SetGoalTolerance(double tol_x, double tol_y, double tol_theta) { /**< not used yet */ }

  void GetCoordFromState(int stateID, int& x, int& y, int& theta) const;
  int GetStateFromCoord(int x, int y, int theta);

  void ConvertStateIDPathintoXYThetaPath(vector<int>* stateIDPath, vector<EnvMAGICLAT3Dpt_t>* xythetaPath); 
  void PrintState(int stateID, bool bVerbose, FILE* fOut=NULL);

  virtual void GetPreds(int TargetStateID, vector<int>* PredIDV, vector<int>* CostV);
  virtual void GetSuccs(int SourceStateID, vector<int>* SuccIDV, vector<int>* CostV, vector<EnvMAGICLATAction_t*>* actionindV=NULL);

  void GetPredsofChangedEdges(vector<nav2dcell_t> const * changedcellsV, vector<int> *preds_of_changededgesIDV);
  void GetSuccsofChangedEdges(vector<nav2dcell_t> const * changedcellsV, vector<int> *succs_of_changededgesIDV);

  virtual void SetAllActionsandAllOutcomes(CMDPSTATE* state);

  virtual int  GetFromToHeuristic(int FromStateID, int ToStateID);
  virtual int  GetGoalHeuristic(int stateID);
  virtual int  GetStartHeuristic(int stateID);

  virtual int	 SizeofCreatedEnv();

  virtual void PrintVars(){};

 protected:

  //hash table of size x_size*y_size. Maps from coords to stateId	
  int HashTableSize;
  vector<EnvMAGICLATHashEntry_t*>* Coord2StateIDHashTable;
  //vector that maps from stateID to coords	
  vector<EnvMAGICLATHashEntry_t*> StateID2CoordTable;
  
  EnvMAGICLATHashEntry_t** Coord2StateIDHashTable_lookup; 

  unsigned int GETHASHBIN(unsigned int X, unsigned int Y, unsigned int Theta);

  EnvMAGICLATHashEntry_t* GetHashEntry_hash(int X, int Y, int Theta);
  EnvMAGICLATHashEntry_t* CreateNewHashEntry_hash(int X, int Y, int Theta);
  EnvMAGICLATHashEntry_t* GetHashEntry_lookup(int X, int Y, int Theta);
  EnvMAGICLATHashEntry_t* CreateNewHashEntry_lookup(int X, int Y, int Theta);

  //pointers to functions
  EnvMAGICLATHashEntry_t* (EnvironmentMAGICLAT::*GetHashEntry)(int X, int Y, int Theta);
  EnvMAGICLATHashEntry_t* (EnvironmentMAGICLAT::*CreateNewHashEntry)(int X, int Y, int Theta);


  virtual void InitializeEnvironment();

  void PrintHashTableHist(FILE* fOut);


};


#endif

