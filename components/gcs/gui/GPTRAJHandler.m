
function GPTRAJHandler(data,name)
global Robots ROBOTS EXPLORE_PATH GTRANSFORM
fprintf('got GPTRAJ message\n');

if ~isempty(data)
    msg = MagicGP_TRAJSerializer('deserialize',data);

    %for all but last robot
    for i=1:msg.NR-1
      t_start = msg.traj_size(i);
      t_end = msg.traj_size(i+1);
      if t_start ~= t_end && ~isempty(GTRANSFORM{i})
        [xr, yr, ar] = gpos_to_rpos(i, msg.POSEX(t_start+1:t_end), msg.POSEY(t_start+1:t_end), msg.POSETHETA(t_start+1:t_end));
        EXPLORE_PATH{i}.x = xr;
        EXPLORE_PATH{i}.y = yr;
        msgName = ['Robot',num2str(i),'/Explore_Path'];
        path = [xr yr ar];
        try
          ROBOTS(i).ipcAPI('publish', msgName, serialize(path));
        catch
          continue;
        end
      end
    end

    %for last robot
    i = msg.NR;
    t_start = msg.traj_size(i);
    t_end = msg.total_size;
    if t_start ~= t_end && ~isempty(GTRANSFORM{i})
      [xr, yr, ar] = gpos_to_rpos(i, msg.POSEX(t_start+1:t_end), msg.POSEY(t_start+1:t_end), msg.POSETHETA(t_start+1:t_end));
      EXPLORE_PATH{i}.x = xr;
      EXPLORE_PATH{i}.y = yr;
      msgName = ['Robot',num2str(i),'/Explore_Path'];
      path = [xr yr ar];
      try
        ROBOTS(i).ipcAPI('publish', msgName, serialize(path));
      catch
      end
    end

    %{
    traj = MagicGP_TRAJECTORYSerializer('deserialize',data);
    if(traj.num_traj_pts > 0)
        traj_array = reshape(traj.traj_array, 6, [])';
        
        id = traj.id;

        EXPLORE_PATH{id}.x = traj_array(:,1);
        EXPLORE_PATH{id}.y = traj_array(:,2);

        [xr, yr, ar] = gpos_to_rpos(id, traj_array(:,1), traj_array(:,2), traj_array(:,3));

        msgName = ['Robot',num2str(id),'/Explore_Path'];
        path = [xr yr ar];
        ROBOTS(id).ipcAPI('publish', msgName, serialize(path));
        

    end
    %}
end

