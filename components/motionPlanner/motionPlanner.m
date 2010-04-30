function motionPlanner()

clear all;

motionPlannerStart;

while(1)
  motionPlannerUpdate;
end



function motionPlannerStart
global MPLANNER

poseSubscribe;
omapSubscribe;
emapSubscribe;


MPLANNER.initialized = 1;



function motionPlannerUpdate
global MPLANNER POSE OMAP EMAP