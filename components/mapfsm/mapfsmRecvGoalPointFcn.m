function mapfsmRecvGoalPointFcn(data, name)

global MP PATH_DATA MPOSE

if ~isempty(data)
    goal = deserialize(data);
    
    if(isequal(size(goal),[1 3]))
        PATH_DATA.goToPointGoal = goal;
    else
        PATH_DATA.goToPointGoal = [goal(:,1) goal(:,2) atan2(goal(2)-MPOSE.y,goal(1)-MPOSE.x)*ones(size(goal,1),1)];
    end
    
    MP.sm = setEvent(MP.sm, 'goToPoint');
end
