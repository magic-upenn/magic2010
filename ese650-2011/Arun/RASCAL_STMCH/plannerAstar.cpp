#include "mex.h"
#include <iostream>
#include <math.h>
#include <queue>
#include <time.h>

using namespace std;
    int newmap[4000000];
    int gvalue[4000000];
class map
{
public:
 float f;
 int x;
 int y;
};
map state;
class Comparemap {
public:
   bool operator()(map& q1, map& q2)
   {
      if (q2.f < q1.f) return true;
      return false;
   }
};
static int epsilon = 1;
void mexFunction(int nlhs, mxArray *plhs[], 
    int nrhs, const mxArray *prhs[])
{
 int  m, n,newx,newy,j,newxprev,newyprev,g;
 double i;
 long int pos[2],a,b,count;
 double h;
 double *robotpos, *targetpos1,*envmap,*output;
 long int targetpos[2];
 int dx[8],dy[8],dir,result[2];
 int path[8];
 double weight[8];
 int count_path = 0;
 //clock_t time_start;
 //time_start=clock();
 priority_queue<map, vector<map>, Comparemap> pq;
 
 dx[0]=dx[1]=dx[2]=-1;
 dx[3]=dx[4]=0;
 dx[5]=dx[6]=dx[7]=1;
 
 dy[0]=dy[3]=dy[5]=-1;
 dy[2]=dy[6]=0;
 dy[1]=dy[4]=dy[7]=1;
 
 for(dir = 0; dir<8; dir ++)
 {
     weight[dir] = sqrt(dx[dir]*dx[dir] + dy[dir]*dy[dir]);
     //printf("Weight: %f \n",weight[dir]);
 }
 
 if (nrhs != 3)
 mexErrMsgTxt("No of input arguments must be three - Costmap,starting point,goal");
 
 if (nlhs != 2)
 mexErrMsgTxt("No of output arguments must be one");
  
  
    n = mxGetN(prhs[0]); // no of columns in the map
    m = mxGetM(prhs[0]); // no of rows in the map x*m+n;
    printf("Row: %d ,Col: %d \n",m,n);
    plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);// change to 1,2
    //plhs[0] = mxCreateDoubleMatrix(2, 10000, mxREAL);// change to 1,2
    envmap=mxGetPr(prhs[0]);

    for(i=0;i<n*m;i++)
    {
        newmap[(long)i] = 0;//envmap[(long)i];
        gvalue[(long)i] = 1000000;
        //printf("gvalue: %f \n",envmap[(long)i]);
    }
    robotpos =  mxGetPr(prhs[1]);
    targetpos1 = mxGetPr(prhs[2]);
    
    output  =   mxGetPr(plhs[0]);
    
    pos[0]=(int)robotpos[0]-1; // Column value
    pos[1]=(int)robotpos[1]-1; // Row value
    targetpos[0]=(int)targetpos1[0]-1; // Column value
    targetpos[1]=(int)targetpos1[1]-1; // Row value

        //printf("epsilon: %d \n",epsilon);
    printf("Start Column : %d, Start Row : %d \n",pos[0],pos[1]);
    printf("End Column : %d, End Row : %d \n",targetpos[0],targetpos[1]);
    //printf("Value : %d \n",(int)val[0]);
  
    gvalue[pos[0]*m+pos[1]]=0;
   
    h=sqrt((pos[0]-targetpos[0])*(pos[0]-targetpos[0]) + (pos[1]-targetpos[1])*(pos[1]-targetpos[1]));
    
    printf("%f \n",h);
    
    state.f=h;
    state.x=pos[0];
    state.y=pos[1];
    newmap[pos[0]*m+pos[1]]=3;
    pq.push(state);
    count=0;
    //return;
  while(( pos[0]!= targetpos[0] || pos[1] != targetpos[1] ))// && ((clock()-time_start)<=0.97*CLOCKS_PER_SEC))//&&count<2000000)
  {
     a=pos[0]*m+pos[1];
     if(newmap[a] != 2) 
     {
        newmap[a]=2;  
           
        for (dir=0; dir<8; dir++)
		{
           newx=pos[0]+dx[dir];
           newy=pos[1]+dy[dir];
  
           g=gvalue[a];
           //printf("Gvalue: %d \n",g);
           //g = envmap[a];
           b=newx*m+newy;

           if((newx>=0 && newx<n && newy>=0 && newy<m))
           {
             if(newmap[b] == 0)
             {
                 h=sqrt((newx-targetpos[0])*(newx-targetpos[0]) + (newy-targetpos[1])*(newy-targetpos[1]));
                 gvalue[b]= g + weight[dir]*envmap[b];
                 //printf("gvalue : %d \n",gvalue[b]);
                 state.f=gvalue[b]+epsilon*h;
                 state.x=newx;
                 state.y=newy;
                 pq.push(state);           
                 newmap[b]=3;// 3 means open
             }        
           }
        }
     }         
     map state2 = pq.top();
     pos[0]=state2.x;
     pos[1]=state2.y;
     //printf("Row : %d, Col : %d \n",pos[0],pos[1]);
     pq.pop();               
     count++;
  }
    
  printf("Finished going forward.... \n");
  for(i=0;i<n*m;i++)
  {
     output[(long)i]=gvalue[(long)i];
  }
  return;
    
  /*if(( pos[0]== targetpos[0] || pos[1] == targetpos[1] ) && count<1000000)
  {
      epsilon=1;
  }
  else
  {
      epsilon=5;
  }*/
    //printf("pos[0] : %d, pos[1] : %d",pos[0],pos[1]);

  
  while( pos[0] != (robotpos[0]-1) || pos[1] != (robotpos[1]-1) )
  {
       //printf("Backtracking Now.... \n");
        
        long gprev=1000000;
        for (dir=0; dir<8; dir++)
        {
            newx=pos[0]+dx[dir];
            newy=pos[1]+dy[dir];
            b=newx*m+newy;
            if(((newx>=0 && newx<n && newy>=0 && newy<m)) && newmap[b]==2)
            {
                g=gvalue[b];
                if(g<gprev)
                {
                    gprev=g;
                    newxprev=newx;
                    newyprev=newy;
                }
            }
        }
        pos[0]=newxprev;
        pos[1]=newyprev;
        newmap[pos[0]*m+pos[1]]=5; //means backtracked
        
        output[count_path*2+0] = pos[1]+1;//Row - Add 1 to get it to matlab basis
        output[count_path*2+1] = pos[0]+1;//Column
        count_path = count_path + 1;
        
        //printf("Col : %d, Row : %d \n",pos[0],pos[1]);
   }     
   plhs[1] = mxCreateDoubleScalar(count_path);
   /*for (dir=0; dir<8; dir++)
   {
        newx=pos[0]+dx[dir];
        newy=pos[1]+dy[dir];
        b=newx*m+newy;
        if(newmap[b]==5)
        {
            result[0]=newx;
            result[1]=newy;
        }
   }*/
         
  // output[0]=result[0]+1;
  // output[1]=result[1]+1;
   
   /*for(i=0;i<n*m;i++)
   {
      output[(long)i]=newmap[(long)i];
   }*/
  
}
