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
#include <iostream>
using namespace std;

#include "../../sbpl/headers.h"




//-----------------------------------------------------------------------------------------------------

ARAPlanner::ARAPlanner(DiscreteSpaceInformation* environment, bool bSearchForward)
{
	bforwardsearch = bSearchForward;

    environment_ = environment;
    
	bsearchuntilfirstsolution = false;
    finitial_eps = ARA_DEFAULT_INITIAL_EPS;
    searchexpands = 0;
    MaxMemoryCounter = 0;
    
    fDeb = fopen("debug.txt", "w");
    
    pSearchStateSpace_ = new ARASearchStateSpace_t;
    
    
    //create the ARA planner
    if(CreateSearchStateSpace(pSearchStateSpace_) != 1)
        {
            printf("ERROR: failed to create statespace\n");
            return;
        }
    
    //set the start and goal states
    if(InitializeSearchStateSpace(pSearchStateSpace_) != 1)
        {
            printf("ERROR: failed to create statespace\n");
            return;
        }    
}

ARAPlanner::~ARAPlanner()
{
  if(pSearchStateSpace_ != NULL){
    //delete the statespace
    DeleteSearchStateSpace(pSearchStateSpace_);
    delete pSearchStateSpace_;
  }
  fclose(fDeb);
}


void ARAPlanner::Initialize_searchinfo(CMDPSTATE* state, ARASearchStateSpace_t* pSearchStateSpace)
{

	ARAState* searchstateinfo = (ARAState*)state->PlannerSpecificData;

	searchstateinfo->MDPstate = state;
	InitializeSearchStateInfo(searchstateinfo, pSearchStateSpace); 
}


CMDPSTATE* ARAPlanner::CreateState(int stateID, ARASearchStateSpace_t* pSearchStateSpace)
{	
	CMDPSTATE* state = NULL;

#if DEBUG
	if(environment_->StateID2IndexMapping[stateID][ARAMDP_STATEID2IND] != -1)
	{
		printf("ERROR in CreateState: state already created\n");
		exit(1);
	}
#endif

	//adds to the tail a state
	state = pSearchStateSpace->searchMDP.AddState(stateID);

	//remember the index of the state
	environment_->StateID2IndexMapping[stateID][ARAMDP_STATEID2IND] = pSearchStateSpace->searchMDP.StateArray.size()-1;

#if DEBUG
	if(state != pSearchStateSpace->searchMDP.StateArray[environment_->StateID2IndexMapping[stateID][ARAMDP_STATEID2IND]])
	{
		printf("ERROR in CreateState: invalid state index\n");
		exit(1);
	}
#endif


	//create search specific info
	state->PlannerSpecificData = (ARAState*)malloc(sizeof(ARAState));	
	Initialize_searchinfo(state, pSearchStateSpace);
	MaxMemoryCounter += sizeof(ARAState);

	return state;

}

CMDPSTATE* ARAPlanner::GetState(int stateID, ARASearchStateSpace_t* pSearchStateSpace)
{	

	if(stateID >= (int)environment_->StateID2IndexMapping.size())
	{
          printf("ERROR int GetState: stateID %d is invalid\n", stateID);
		exit(1);
	}

	if(environment_->StateID2IndexMapping[stateID][ARAMDP_STATEID2IND] == -1)
		return CreateState(stateID, pSearchStateSpace);
	else
		return pSearchStateSpace->searchMDP.StateArray[environment_->StateID2IndexMapping[stateID][ARAMDP_STATEID2IND]];

}



//-----------------------------------------------------------------------------------------------------




int ARAPlanner::ComputeHeuristic(CMDPSTATE* MDPstate, ARASearchStateSpace_t* pSearchStateSpace)
{
	//compute heuristic for search

	if(bforwardsearch)
	{

#if MEM_CHECK == 1
		//int WasEn = DisableMemCheck();
#endif

		//forward search: heur = distance from state to searchgoal which is Goal ARAState
		int retv =  environment_->GetGoalHeuristic(MDPstate->StateID);

#if MEM_CHECK == 1
		//if (WasEn)
		//	EnableMemCheck();
#endif

		return retv;

	}
	else
	{
		//backward search: heur = distance from searchgoal to state
		return environment_->GetStartHeuristic(MDPstate->StateID);
	}
}


//initialization of a state
void ARAPlanner::InitializeSearchStateInfo(ARAState* state, ARASearchStateSpace_t* pSearchStateSpace)
{
	state->g = INFINITECOST;
	state->v = INFINITECOST;
	state->iterationclosed = 0;
	state->callnumberaccessed = pSearchStateSpace->callnumber;
	state->bestnextstate = NULL;
	state->costtobestnextstate = INFINITECOST;
	state->heapindex = 0;
	state->listelem[ARA_INCONS_LIST_ID] = 0;
	state->numofexpands = 0;

	state->bestpredstate = NULL;

	//compute heuristics
#if USE_HEUR
	if(pSearchStateSpace->searchgoalstate != NULL)
		state->h = ComputeHeuristic(state->MDPstate, pSearchStateSpace); 
	else 
		state->h = 0;
#else
	state->h = 0;
#endif


}



//re-initialization of a state
void ARAPlanner::ReInitializeSearchStateInfo(ARAState* state, ARASearchStateSpace_t* pSearchStateSpace)
{
	state->g = INFINITECOST;
	state->v = INFINITECOST;
	state->iterationclosed = 0;
	state->callnumberaccessed = pSearchStateSpace->callnumber;
	state->bestnextstate = NULL;
	state->costtobestnextstate = INFINITECOST;
	state->heapindex = 0;
	state->listelem[ARA_INCONS_LIST_ID] = 0;
	state->numofexpands = 0;

	state->bestpredstate = NULL;

	//compute heuristics
#if USE_HEUR

	if(pSearchStateSpace->searchgoalstate != NULL)
	{
		state->h = ComputeHeuristic(state->MDPstate, pSearchStateSpace); 
	}
	else 
		state->h = 0;

#else

	state->h = 0;

#endif


}



void ARAPlanner::DeleteSearchStateData(ARAState* state)
{
	//no memory was allocated
	MaxMemoryCounter = 0;
	return;
}



//used for backward search
void ARAPlanner::UpdatePreds(ARAState* state, ARASearchStateSpace_t* pSearchStateSpace)
{
    vector<int> PredIDV;
    vector<int> CostV;
	CKey key;
	ARAState *predstate;

    environment_->GetPreds(state->MDPstate->StateID, &PredIDV, &CostV);

	//iterate through predecessors of s
	for(int pind = 0; pind < (int)PredIDV.size(); pind++)
	{
		CMDPSTATE* PredMDPState = GetState(PredIDV[pind], pSearchStateSpace);
		predstate = (ARAState*)(PredMDPState->PlannerSpecificData);
		if(predstate->callnumberaccessed != pSearchStateSpace->callnumber)
			ReInitializeSearchStateInfo(predstate, pSearchStateSpace);

		//see if we can improve the value of predstate
		if(predstate->g > state->v + CostV[pind])
		{
			predstate->g = state->v + CostV[pind];
			predstate->bestnextstate = state->MDPstate;
			predstate->costtobestnextstate = CostV[pind];

			//re-insert into heap if not closed yet
			if(predstate->iterationclosed != pSearchStateSpace->searchiteration)
			{
				key.key[0] = predstate->g + (int)(pSearchStateSpace->eps*predstate->h);
				//key.key[1] = predstate->h;
				if(predstate->heapindex != 0)
					pSearchStateSpace->heap->updateheap(predstate,key);
				else
					pSearchStateSpace->heap->insertheap(predstate,key);
			}
			//take care of incons list
			else if(predstate->listelem[ARA_INCONS_LIST_ID] == NULL)
			{
				pSearchStateSpace->inconslist->insert(predstate, ARA_INCONS_LIST_ID);
			}
		}
	} //for predecessors

}

//used for forward search
void ARAPlanner::UpdateSuccs(ARAState* state, ARASearchStateSpace_t* pSearchStateSpace)
{
    vector<int> SuccIDV;
    vector<int> CostV;
	CKey key;
	ARAState *succstate;

    environment_->GetSuccs(state->MDPstate->StateID, &SuccIDV, &CostV);

	//iterate through predecessors of s
	for(int sind = 0; sind < (int)SuccIDV.size(); sind++)
	{
		CMDPSTATE* SuccMDPState = GetState(SuccIDV[sind], pSearchStateSpace);
		int cost = CostV[sind];

		succstate = (ARAState*)(SuccMDPState->PlannerSpecificData);
		if(succstate->callnumberaccessed != pSearchStateSpace->callnumber)
			ReInitializeSearchStateInfo(succstate, pSearchStateSpace);

		//see if we can improve the value of succstate
		//taking into account the cost of action
		if(succstate->g > state->v + cost)
		{
			succstate->g = state->v + cost;
			succstate->bestpredstate = state->MDPstate; 

			//re-insert into heap if not closed yet
			if(succstate->iterationclosed != pSearchStateSpace->searchiteration)
			{
				
				key.key[0] = succstate->g + (int)(pSearchStateSpace->eps*succstate->h);

				//key.key[1] = succstate->h;

				if(succstate->heapindex != 0)
					pSearchStateSpace->heap->updateheap(succstate,key);
				else
					pSearchStateSpace->heap->insertheap(succstate,key);
			}
			//take care of incons list
			else if(succstate->listelem[ARA_INCONS_LIST_ID] == NULL)
			{
				pSearchStateSpace->inconslist->insert(succstate, ARA_INCONS_LIST_ID);
			}
		} //check for cost improvement 

	} //for actions
}

//TODO-debugmax - add obsthresh and other thresholds to other environments in 3dkin
int ARAPlanner::GetGVal(int StateID, ARASearchStateSpace_t* pSearchStateSpace)
{
	 CMDPSTATE* cmdp_state = GetState(StateID, pSearchStateSpace);
	 ARAState* state = (ARAState*)cmdp_state->PlannerSpecificData;
	 return state->g;
}

//returns 1 if the solution is found, 0 if the solution does not exist and 2 if it ran out of time
int ARAPlanner::ImprovePath(ARASearchStateSpace_t* pSearchStateSpace, double MaxNumofSecs)
{
	int expands;
	ARAState *state, *searchgoalstate;
	CKey key, minkey;
	CKey goalkey;

	expands = 0;


	if(pSearchStateSpace->searchgoalstate == NULL)
	{
		printf("ERROR searching: no goal state is set\n");
		exit(1);
	}

	//goal state
	searchgoalstate = (ARAState*)(pSearchStateSpace->searchgoalstate->PlannerSpecificData);
	if(searchgoalstate->callnumberaccessed != pSearchStateSpace->callnumber)
		ReInitializeSearchStateInfo(searchgoalstate, pSearchStateSpace);

	//set goal key
	goalkey.key[0] = searchgoalstate->g;
	//goalkey.key[1] = searchgoalstate->h;

	//expand states until done
	minkey = pSearchStateSpace->heap->getminkeyheap();
	CKey oldkey = minkey;
	while(!pSearchStateSpace->heap->emptyheap() && minkey.key[0] < INFINITECOST && goalkey > minkey &&
		(clock()-TimeStarted) < MaxNumofSecs*(double)CLOCKS_PER_SEC) 
    {

		//get the state		
		state = (ARAState*)pSearchStateSpace->heap->deleteminheap();


#if DEBUG
		//fprintf(fDeb, "expanding state(%d): h=%d g=%u key=%u v=%u iterc=%d callnuma=%d expands=%d (g(goal)=%u)\n",
		//	state->MDPstate->StateID, state->h, state->g, state->g+(int)(pSearchStateSpace->eps*state->h), state->v, 
		//	state->iterationclosed, state->callnumberaccessed, state->numofexpands, searchgoalstate->g);
		//fprintf(fDeb, "expanding: ");
		//PrintSearchState(state, fDeb);
		if(state->listelem[ARA_INCONS_LIST_ID]  != NULL)
		{
			fprintf(fDeb, "ERROR: expanding a state from inconslist\n");
			printf("ERROR: expanding a state from inconslist\n");
			exit(1);
		}
		//fflush(fDeb);
#endif

#if DEBUG
		if(minkey.key[0] < oldkey.key[0] && fabs(this->finitial_eps - 1.0) < ERR_EPS)
		{
			//printf("WARN in search: the sequence of keys decreases\n");
			//exit(1);
		}
		oldkey = minkey;
#endif

		if(state->v == state->g)
		{
			printf("ERROR: consistent state is being expanded\n");
#if DEBUG
			fprintf(fDeb, "ERROR: consistent state is being expanded\n");
			exit(1);
#endif
		}

		//recompute state value      
		state->v = state->g;
		state->iterationclosed = pSearchStateSpace->searchiteration;

		//new expand      
		expands++;
		state->numofexpands++;


		if(bforwardsearch == false)
			UpdatePreds(state, pSearchStateSpace);
		else
			UpdateSuccs(state, pSearchStateSpace);
		
		//recompute minkey
		minkey = pSearchStateSpace->heap->getminkeyheap();

		//recompute goalkey if necessary
		if(goalkey.key[0] != (int)searchgoalstate->g)
		{
			//printf("re-computing goal key\n");
			//recompute the goal key (heuristics should be zero)
			goalkey.key[0] = searchgoalstate->g;
			//goalkey.key[1] = searchgoalstate->h;
		}

		if(expands%100000 == 0 && expands > 0)
		{
			printf("expands so far=%u\n", expands);
		}

	}

	int retv = 1;
	if(searchgoalstate->g == INFINITECOST && pSearchStateSpace->heap->emptyheap())
	{
		printf("solution does not exist: search exited because heap is empty\n");
		retv = 0;
	}
	else if(!pSearchStateSpace->heap->emptyheap() && goalkey > minkey)
	{
		printf("search exited because it ran out of time\n");
		retv = 2;
	}
	else if(searchgoalstate->g == INFINITECOST && !pSearchStateSpace->heap->emptyheap())
	{
		printf("solution does not exist: search exited because all candidates for expansion have infinite heuristics\n");
		retv = 0;
	}
	else
	{
		printf("search exited with a solution for eps=%.3f\n", pSearchStateSpace->eps);
		retv = 1;
	}

	//fprintf(fDeb, "expanded=%d\n", expands);

	searchexpands += expands;

	return retv;		
}


void ARAPlanner::BuildNewOPENList(ARASearchStateSpace_t* pSearchStateSpace)
{
	ARAState *state;
	CKey key;
	CHeap* pheap = pSearchStateSpace->heap;
	CList* pinconslist = pSearchStateSpace->inconslist; 
		
	//move incons into open
	while(pinconslist->firstelement != NULL)
	  {
	    state = (ARAState*)pinconslist->firstelement->liststate;
	    
	    //compute f-value
	    key.key[0] = state->g + (int)(pSearchStateSpace->eps*state->h);
	    //key.key[1] = state->h;
	    
	    //insert into OPEN
	    pheap->insertheap(state, key);
	    //remove from INCONS
	    pinconslist->remove(state, ARA_INCONS_LIST_ID);
	  }
}


void ARAPlanner::Reevaluatefvals(ARASearchStateSpace_t* pSearchStateSpace)
{
	CKey key;
	int i;
	CHeap* pheap = pSearchStateSpace->heap;
	
	//recompute priorities for states in OPEN and reorder it
	for (i = 1; i <= pheap->currentsize; ++i)
	  {
		ARAState* state = (ARAState*)pheap->heap[i].heapstate;
	    pheap->heap[i].key.key[0] = state->g + 
	      (int)(pSearchStateSpace->eps*state->h); 
	    //pheap->heap[i].key.key[1] = state->h; 
	  }
	pheap->makeheap();

	pSearchStateSpace->bReevaluatefvals = false;
}




//creates (allocates memory) search state space
//does not initialize search statespace
int ARAPlanner::CreateSearchStateSpace(ARASearchStateSpace_t* pSearchStateSpace)
{

	//create a heap
	pSearchStateSpace->heap = new CHeap;
	pSearchStateSpace->inconslist = new CList;
	MaxMemoryCounter += sizeof(CHeap);
	MaxMemoryCounter += sizeof(CList);

	pSearchStateSpace->searchgoalstate = NULL;
	pSearchStateSpace->searchstartstate = NULL;

	searchexpands = 0;


    pSearchStateSpace->bReinitializeSearchStateSpace = false;
	
	return 1;
}

//deallocates memory used by SearchStateSpace
void ARAPlanner::DeleteSearchStateSpace(ARASearchStateSpace_t* pSearchStateSpace)
{
	if(pSearchStateSpace->heap != NULL)
	{
		pSearchStateSpace->heap->makeemptyheap();
		delete pSearchStateSpace->heap;
		pSearchStateSpace->heap = NULL;
	}

	if(pSearchStateSpace->inconslist != NULL)
	{
		pSearchStateSpace->inconslist->makeemptylist(ARA_INCONS_LIST_ID);
		delete pSearchStateSpace->inconslist;
		pSearchStateSpace->inconslist = NULL;
	}

	//delete the states themselves
	int iend = (int)pSearchStateSpace->searchMDP.StateArray.size();
	for(int i=0; i < iend; i++)
	{
		CMDPSTATE* state = pSearchStateSpace->searchMDP.StateArray[i];
    if(state != NULL && state->PlannerSpecificData != NULL){
      DeleteSearchStateData((ARAState*)state->PlannerSpecificData);
      free((ARAState*)state->PlannerSpecificData);
      state->PlannerSpecificData = NULL;
    }
	}
	pSearchStateSpace->searchMDP.Delete();
}



//reset properly search state space
//needs to be done before deleting states
int ARAPlanner::ResetSearchStateSpace(ARASearchStateSpace_t* pSearchStateSpace)
{
	pSearchStateSpace->heap->makeemptyheap();
	pSearchStateSpace->inconslist->makeemptylist(ARA_INCONS_LIST_ID);

	return 1;
}

//initialization before each search
void ARAPlanner::ReInitializeSearchStateSpace(ARASearchStateSpace_t* pSearchStateSpace)
{
  printf("\n\nRE-INIT PLANNER!!!\n\n");
	CKey key;

	//increase callnumber
	pSearchStateSpace->callnumber++;

	//reset iteration
	pSearchStateSpace->searchiteration = 0;
	pSearchStateSpace->bNewSearchIteration = true;

#if DEBUG
    fprintf(fDeb, "reinitializing search state-space (new call number=%d search iter=%d)\n", 
            pSearchStateSpace->callnumber,pSearchStateSpace->searchiteration );
#endif



	pSearchStateSpace->heap->makeemptyheap();
	pSearchStateSpace->inconslist->makeemptylist(ARA_INCONS_LIST_ID);

    //reset 
	pSearchStateSpace->eps = this->finitial_eps;
    pSearchStateSpace->eps_satisfied = INFINITECOST;

	//initialize start state
	ARAState* startstateinfo = (ARAState*)(pSearchStateSpace->searchstartstate->PlannerSpecificData);
	if(startstateinfo->callnumberaccessed != pSearchStateSpace->callnumber)
		ReInitializeSearchStateInfo(startstateinfo, pSearchStateSpace);

	startstateinfo->g = 0;

	//insert start state into the heap
	key.key[0] = (long int)(pSearchStateSpace->eps*startstateinfo->h);
	//key.key[1] = startstateinfo->h;
	pSearchStateSpace->heap->insertheap(startstateinfo, key);

    pSearchStateSpace->bReinitializeSearchStateSpace = false;
	pSearchStateSpace->bReevaluatefvals = false;
}

//very first initialization
int ARAPlanner::InitializeSearchStateSpace(ARASearchStateSpace_t* pSearchStateSpace)
{

	if(pSearchStateSpace->heap->currentsize != 0 || 
		pSearchStateSpace->inconslist->currentsize != 0)
	{
		printf("ERROR in InitializeSearchStateSpace: heap or list is not empty\n");
		exit(1);
	}

	pSearchStateSpace->eps = this->finitial_eps;
    pSearchStateSpace->eps_satisfied = INFINITECOST;
	pSearchStateSpace->searchiteration = 0;
	pSearchStateSpace->bNewSearchIteration = true;
	pSearchStateSpace->callnumber = 0;
	pSearchStateSpace->bReevaluatefvals = false;


	//create and set the search start state
	pSearchStateSpace->searchgoalstate = NULL;
	//pSearchStateSpace->searchstartstate = GetState(SearchStartStateID, pSearchStateSpace);
    pSearchStateSpace->searchstartstate = NULL;
	

    pSearchStateSpace->bReinitializeSearchStateSpace = true;

	return 1;

}


int ARAPlanner::SetSearchGoalState(int SearchGoalStateID, ARASearchStateSpace_t* pSearchStateSpace)
{
	if(pSearchStateSpace->searchgoalstate == NULL || 
		pSearchStateSpace->searchgoalstate->StateID != SearchGoalStateID)
	{
		pSearchStateSpace->searchgoalstate = GetState(SearchGoalStateID, pSearchStateSpace);

		//should be new search iteration
		pSearchStateSpace->eps_satisfied = INFINITECOST;
		pSearchStateSpace->bNewSearchIteration = true;
		pSearchStateSpace_->eps = this->finitial_eps;


		//recompute heuristic for the heap if heuristics is used
#if USE_HEUR
		for(int i = 0; i < (int)pSearchStateSpace->searchMDP.StateArray.size(); i++)
		{
			CMDPSTATE* MDPstate = pSearchStateSpace->searchMDP.StateArray[i];
			ARAState* state = (ARAState*)MDPstate->PlannerSpecificData;
			state->h = ComputeHeuristic(MDPstate, pSearchStateSpace);
		}
		
		pSearchStateSpace->bReevaluatefvals = true;
#endif
	}


	return 1;

}


int ARAPlanner::SetSearchStartState(int SearchStartStateID, ARASearchStateSpace_t* pSearchStateSpace)
{

	CMDPSTATE* MDPstate = GetState(SearchStartStateID, pSearchStateSpace);

	if(MDPstate !=  pSearchStateSpace->searchstartstate)
	{	
		pSearchStateSpace->searchstartstate = MDPstate;
		pSearchStateSpace->bReinitializeSearchStateSpace = true;
	}

	return 1;

}



int ARAPlanner::ReconstructPath(ARASearchStateSpace_t* pSearchStateSpace)
{	


	if(bforwardsearch) //nothing to do, if search is backward
	{
		CMDPSTATE* MDPstate = pSearchStateSpace->searchgoalstate;
		CMDPSTATE* PredMDPstate;
		ARAState *predstateinfo, *stateinfo;



#if DEBUG
		fprintf(fDeb, "reconstructing a path:\n");
#endif

		while(MDPstate != pSearchStateSpace->searchstartstate)
		{
			stateinfo = (ARAState*)MDPstate->PlannerSpecificData;

#if DEBUG
			PrintSearchState(stateinfo, fDeb);
#endif
			if(stateinfo->g == INFINITECOST)
			{	
				//printf("ERROR in ReconstructPath: g of the state on the path is INFINITE\n");
				//exit(1);
				return -1;
			}

			if(stateinfo->bestpredstate == NULL)
			{
				printf("ERROR in ReconstructPath: bestpred is NULL\n");
				exit(1);
			}

			//get the parent state
			PredMDPstate = stateinfo->bestpredstate;
			predstateinfo = (ARAState*)PredMDPstate->PlannerSpecificData;

			//set its best next info
			predstateinfo->bestnextstate = MDPstate;

			//check the decrease of g-values along the path
			if(predstateinfo->v >= stateinfo->g)
			{
				printf("ERROR in ReconstructPath: g-values are non-decreasing\n");			
				PrintSearchState(predstateinfo, fDeb);
				exit(1);
			}

			//transition back
			MDPstate = PredMDPstate;
		}
	}

	return 1;
}



void ARAPlanner::PrintSearchPath(ARASearchStateSpace_t* pSearchStateSpace, FILE* fOut)
{
	ARAState* searchstateinfo;
	CMDPSTATE* state;
	int goalID;
	int PathCost;

	if(bforwardsearch)
	{
		state  = pSearchStateSpace->searchstartstate;
		goalID = pSearchStateSpace->searchgoalstate->StateID;
	}
	else
	{
		state = pSearchStateSpace->searchgoalstate;
		goalID = pSearchStateSpace->searchstartstate->StateID;
	}
	if(fOut == NULL)
		fOut = stdout;

	PathCost = ((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData)->g;

	fprintf(fOut, "Printing a path from state %d to the goal state %d\n", 
			state->StateID, pSearchStateSpace->searchgoalstate->StateID);
	fprintf(fOut, "Path cost = %d:\n", PathCost);
			
	
	environment_->PrintState(state->StateID, false, fOut);

	int costFromStart = 0;
	while(state->StateID != goalID)
	{
		fprintf(fOut, "state %d ", state->StateID);

		if(state->PlannerSpecificData == NULL)
		{
			fprintf(fOut, "path does not exist since search data does not exist\n");
			break;
		}

		searchstateinfo = (ARAState*)state->PlannerSpecificData;

		if(searchstateinfo->bestnextstate == NULL)
		{
			fprintf(fOut, "path does not exist since bestnextstate == NULL\n");
			break;
		}
		if(searchstateinfo->g == INFINITECOST)
		{
			fprintf(fOut, "path does not exist since bestnextstate == NULL\n");
			break;
		}

		int costToGoal = PathCost - costFromStart;
		int transcost = searchstateinfo->g - ((ARAState*)(searchstateinfo->bestnextstate->PlannerSpecificData))->v;
		if(bforwardsearch)
			transcost = -transcost;

		costFromStart += transcost;

		fprintf(fOut, "g=%d-->state %d, h = %d ctg = %d  ", searchstateinfo->g, 			
			searchstateinfo->bestnextstate->StateID, searchstateinfo->h, costToGoal);

		state = searchstateinfo->bestnextstate;

		environment_->PrintState(state->StateID, false, fOut);



	}
}

void ARAPlanner::PrintSearchState(ARAState* state, FILE* fOut)
{
	fprintf(fOut, "state %d: h=%d g=%u v=%u iterc=%d callnuma=%d expands=%d heapind=%d inconslist=%d\n",
		state->MDPstate->StateID, state->h, state->g, state->v, 
		state->iterationclosed, state->callnumberaccessed, state->numofexpands, state->heapindex, state->listelem[ARA_INCONS_LIST_ID]?1:0);
	environment_->PrintState(state->MDPstate->StateID, true, fOut);

}



int ARAPlanner::getHeurValue(ARASearchStateSpace_t* pSearchStateSpace, int StateID)
{
	CMDPSTATE* MDPstate = GetState(StateID, pSearchStateSpace);
	ARAState* searchstateinfo = (ARAState*)MDPstate->PlannerSpecificData;
	return searchstateinfo->h;
}


vector<int> ARAPlanner::GetSearchPath(ARASearchStateSpace_t* pSearchStateSpace, int& solcost)
{
  vector<int> SuccIDV;
  vector<int> CostV;
  vector<int> wholePathIds;
  ARAState* searchstateinfo;
  CMDPSTATE* state = NULL; 
  CMDPSTATE* goalstate = NULL;
  CMDPSTATE* startstate=NULL;
  
  if(bforwardsearch)
    {	
      startstate = pSearchStateSpace->searchstartstate;
      goalstate = pSearchStateSpace->searchgoalstate;
      
      //reconstruct the path by setting bestnextstate pointers appropriately
      ReconstructPath(pSearchStateSpace);
    }
  else
    {
      startstate = pSearchStateSpace->searchgoalstate;
      goalstate = pSearchStateSpace->searchstartstate;
    }
  
  
  state = startstate;
  
  wholePathIds.push_back(state->StateID);
  solcost = 0;
  
  FILE* fOut = stdout;
  while(state->StateID != goalstate->StateID)
    {
      if(state->PlannerSpecificData == NULL)
	{
	  fprintf(fOut, "path does not exist since search data does not exist\n");
	  break;
	}
      
      searchstateinfo = (ARAState*)state->PlannerSpecificData;
      
      if(searchstateinfo->bestnextstate == NULL)
	{
	  fprintf(fOut, "path does not exist since bestnextstate == NULL\n");
	  break;
	}
      if(searchstateinfo->g == INFINITECOST)
	{
	  fprintf(fOut, "path does not exist since bestnextstate == NULL\n");
	  break;
	}
      
      environment_->GetSuccs(state->StateID, &SuccIDV, &CostV);
      int actioncost = INFINITECOST;
      for(int i = 0; i < (int)SuccIDV.size(); i++)
        {   
	  
	  if(SuccIDV.at(i) == searchstateinfo->bestnextstate->StateID)
	    actioncost = CostV.at(i);
	  
        }
      if(actioncost == INFINITECOST)
	printf("WARNING: actioncost = %d\n", actioncost);
      
      solcost += actioncost;
      
      //fprintf(fDeb, "actioncost=%d between states %d and %d\n", 
      //        actioncost, state->StateID, searchstateinfo->bestnextstate->StateID);
      //environment_->PrintState(state->StateID, false, fDeb);
      //environment_->PrintState(searchstateinfo->bestnextstate->StateID, false, fDeb);
      
      
#if DEBUG
      ARAState* nextstateinfo = (ARAState*)(searchstateinfo->bestnextstate->PlannerSpecificData);
      if(actioncost != abs((int)(searchstateinfo->g - nextstateinfo->g)) && pSearchStateSpace->eps_satisfied <= 1.001)
	{
	  fprintf(fDeb, "ERROR: actioncost=%d is not matching the difference in g-values of %d\n", 
		  actioncost, abs((int)(searchstateinfo->g - nextstateinfo->g)));
	  printf("ERROR: actioncost=%d is not matching the difference in g-values of %d\n", 
		 actioncost,abs((int)(searchstateinfo->g - nextstateinfo->g)));
	  PrintSearchState(searchstateinfo, fDeb);
	  PrintSearchState(nextstateinfo, fDeb);
	}
#endif
      
      
      state = searchstateinfo->bestnextstate;
      
      wholePathIds.push_back(state->StateID);
    }


  return wholePathIds;
}



bool ARAPlanner::Search(ARASearchStateSpace_t* pSearchStateSpace, vector<int>& pathIds, int & PathCost, bool bFirstSolution, bool bOptimalSolution, double MaxNumofSecs)
{
	CKey key;
	TimeStarted = clock();
    searchexpands = 0;

#if DEBUG
	fprintf(fDeb, "new search call (call number=%d)\n", pSearchStateSpace->callnumber);
#endif

    if(pSearchStateSpace->bReinitializeSearchStateSpace == true){
        //re-initialize state space 
        ReInitializeSearchStateSpace(pSearchStateSpace);
    }


	if(bOptimalSolution)
	{
		pSearchStateSpace->eps = 1;
		MaxNumofSecs = INFINITECOST;
	}
	else if(bFirstSolution)
	{
		MaxNumofSecs = INFINITECOST;
	}

	//ensure heuristics are up-to-date
	environment_->EnsureHeuristicsUpdated((bforwardsearch==true));

	//the main loop of ARA*
	int prevexpands = 0;
	clock_t loop_time;
	while(pSearchStateSpace->eps_satisfied > ARA_FINAL_EPS && 
		(clock()- TimeStarted) < MaxNumofSecs*(double)CLOCKS_PER_SEC)
	{
        loop_time = clock();
		//decrease eps for all subsequent iterations
		if(fabs(pSearchStateSpace->eps_satisfied - pSearchStateSpace->eps) < ERR_EPS && !bFirstSolution)
		{
			pSearchStateSpace->eps = pSearchStateSpace->eps - ARA_DECREASE_EPS;
			if(pSearchStateSpace->eps < ARA_FINAL_EPS)
				pSearchStateSpace->eps = ARA_FINAL_EPS;

			//the priorities need to be updated
			pSearchStateSpace->bReevaluatefvals = true; 

			//it will be a new search
			pSearchStateSpace->bNewSearchIteration = true;

			//build a new open list by merging it with incons one
			BuildNewOPENList(pSearchStateSpace); 

		}

		if(pSearchStateSpace->bNewSearchIteration)
		{
			pSearchStateSpace->searchiteration++;
			pSearchStateSpace->bNewSearchIteration = false;
		}

		//re-compute f-values if necessary and reorder the heap
		if(pSearchStateSpace->bReevaluatefvals) 
			Reevaluatefvals(pSearchStateSpace);

		//improve or compute path
		if(ImprovePath(pSearchStateSpace, MaxNumofSecs) == 1){
            pSearchStateSpace->eps_satisfied = pSearchStateSpace->eps;
        }

		//print the solution cost and eps bound
		printf("eps=%f expands=%d g(searchgoal)=%d time=%.3f\n", pSearchStateSpace->eps_satisfied, searchexpands - prevexpands,
							((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData)->g,double(clock()-loop_time)/CLOCKS_PER_SEC);

#if DEBUG
        fprintf(fDeb, "eps=%f expands=%d g(searchgoal)=%d time=%.3f\n", pSearchStateSpace->eps_satisfied, searchexpands - prevexpands,
							((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData)->g,double(clock()-loop_time)/CLOCKS_PER_SEC);
		PrintSearchState((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData, fDeb);
#endif
		prevexpands = searchexpands;


		//if just the first solution then we are done
		if(bFirstSolution)
			break;

		//no solution exists
		if(((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData)->g == INFINITECOST)
			break;

	}


#if DEBUG
	fflush(fDeb);
#endif

	PathCost = ((ARAState*)pSearchStateSpace->searchgoalstate->PlannerSpecificData)->g;
	MaxMemoryCounter += environment_->StateID2IndexMapping.size()*sizeof(int);
	
	printf("MaxMemoryCounter = %d\n", MaxMemoryCounter);

	int solcost = INFINITECOST;
	bool ret = false;
	if(PathCost == INFINITECOST)
	{
		printf("could not find a solution\n");
		ret = false;
	}
	else
	{
		printf("solution is found\n");      
    	pathIds = GetSearchPath(pSearchStateSpace, solcost);
        ret = true;
	}

	printf("total expands this call = %d, planning time = %.3f secs, solution cost=%d\n", 
           searchexpands, (clock()-TimeStarted)/((double)CLOCKS_PER_SEC), solcost);
    

    //fprintf(fStat, "%d %d\n", searchexpands, solcost);

	return ret;

}


//-----------------------------Interface function-----------------------------------------------------
//returns 1 if found a solution, and 0 otherwise
int ARAPlanner::replan(double allocated_time_secs, vector<int>* solution_stateIDs_V)
{
	int solcost;

	return replan(allocated_time_secs, solution_stateIDs_V, &solcost);
	
}

//returns 1 if found a solution, and 0 otherwise
int ARAPlanner::replan(double allocated_time_secs, vector<int>* solution_stateIDs_V, int* psolcost)
{
  vector<int> pathIds; 
  bool bFound = false;
  int PathCost;
  bool bFirstSolution = this->bsearchuntilfirstsolution;
  bool bOptimalSolution = false;
  *psolcost = 0;
  
  printf("planner: replan called (bFirstSol=%d, bOptSol=%d)\n", bFirstSolution, bOptimalSolution);
  
  //plan
  if((bFound = Search(pSearchStateSpace_, pathIds, PathCost, bFirstSolution, bOptimalSolution, allocated_time_secs)) == false) 
    {
      printf("failed to find a solution\n");
    }
  
  //copy the solution
  *solution_stateIDs_V = pathIds;
  *psolcost = PathCost;
  
  return (int)bFound;

}


int ARAPlanner::set_goal(int goal_stateID)
{

	printf("planner: setting goal to %d\n", goal_stateID);
	environment_->PrintState(goal_stateID, true, stdout);

	if(bforwardsearch)
	{	
		if(SetSearchGoalState(goal_stateID, pSearchStateSpace_) != 1)
			{
				printf("ERROR: failed to set search goal state\n");
				return 0;
			}
	}
	else
	{
	    if(SetSearchStartState(goal_stateID, pSearchStateSpace_) != 1)
        {
            printf("ERROR: failed to set search start state\n");
            return 0;
        }
	}

    return 1;
}


int ARAPlanner::set_start(int start_stateID)
{

	printf("planner: setting start to %d\n", start_stateID);
	environment_->PrintState(start_stateID, true, stdout);

	if(bforwardsearch)
	{	

	    if(SetSearchStartState(start_stateID, pSearchStateSpace_) != 1)
        {
            printf("ERROR: failed to set search start state\n");
            return 0;
        }
	}
	else
	{
	    if(SetSearchGoalState(start_stateID, pSearchStateSpace_) != 1)
        {
            printf("ERROR: failed to set search goal state\n");
            return 0;
        }
	}

    return 1;

}



void ARAPlanner::costs_changed(StateChangeQuery const & stateChange)
{


    pSearchStateSpace_->bReinitializeSearchStateSpace = true;


}

void ARAPlanner::costs_changed()
{

    pSearchStateSpace_->bReinitializeSearchStateSpace = true;

}



int ARAPlanner::force_planning_from_scratch()
{
	printf("planner: forceplanfromscratch set\n");

    pSearchStateSpace_->bReinitializeSearchStateSpace = true;

    return 1;
}


int ARAPlanner::set_search_mode(bool bSearchUntilFirstSolution)
{

	printf("planner: search mode set to %d\n", bSearchUntilFirstSolution);

	bsearchuntilfirstsolution = bSearchUntilFirstSolution;

	return 1;
}


void ARAPlanner::print_searchpath(FILE* fOut)
{
	PrintSearchPath(pSearchStateSpace_, fOut);
}


//---------------------------------------------------------------------------------------------------------

