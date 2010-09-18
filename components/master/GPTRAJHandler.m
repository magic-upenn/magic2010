
function GPTRAJHandler(data,name)
global Robots ROBOTS EXPLORE_PATH
fprintf('got GPTRAJ message\n');

if ~isempty(data)
    traj = MagicGP_TRAJECTORYSerializer('deserialize',data);
    if(traj.num_traj_pts > 0)
        traj_array = reshape(traj.traj_array, 6, [])';
        
        %set traj to the appropriate robot based on name
        id = traj.id;
        %Robots(id).traj.data = traj_array;

        EXPLORE_PATH{id}.x = traj_array(:,1);
        EXPLORE_PATH{id}.y = traj_array(:,2);

        [xr, yr, ar] = gpos_to_rpos(id, traj_array(:,1), traj_array(:,2), traj_array(:,3));

        msgName = ['Robot',num2str(id),'/Explore_Path'];
        path = [xr yr ar];
        ROBOTS(id).ipcAPI('publish', msgName, serialize(path));
        

        %figure(id+1); hold on;
        %if Robots(id).traj.handle ~= -1
            %delete(Robots(id).traj.handle);
        %end
        %plot(traj_array(1,1), traj_array(1,2), 'gv');
        %Robots(id).traj.handle = plot(traj_array(:,1), traj_array(:,2), 'y-');
        %hold off;

%         ROBOTS(id).ipcAPI('publishVC', sprintf('Robot%d/Waypoints',id),MagicGP_TRAJECTORYSerializer('serialize', traj));
        
        %end
    end
end

% UpdateGoals();

% end
