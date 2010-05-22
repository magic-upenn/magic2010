  traj_c = [];
% filepath = '../Release/';
filepath = '';
 [cover_map cost_map elev_map] = inputM([filepath 'Map.txt']);
figure(2);
image(double(cost_map));
title('original cost map');
axis equal
axis xy


figure(3);
image(double(elev_map));
title('original elev map');
axis equal
axis xy

for rep=1:400
    
    
    
    [cover_map2 inf_cost_map2 elev_map2] = inputM([filepath 'Map_out.txt']);
    
    figure(1);
    image(cover_map2);
    title('post coverage');
    axis equal;
    axis xy;
    
    
    figure(4);
    image(inf_cost_map2);
    title('cost out');
    axis equal
    axis xy;
    
    [djikstra] = input_djikstra([filepath 'Map_extra.txt']);
    figure(5);
    djikstra(djikstra==100000000) = 10000;
    image(70*double(djikstra)/double(max(max(djikstra))));
    title('djikstra');
    axis equal;
    axis xy;
    
    [score, traj] = input_mapMST([filepath 'Map_traj.txt']);
    traj = (reshape(traj,6, []))';
    traj_c = vertcat(traj_c, traj);
    figure(5);
    hold on;
    plot(traj_c(:,2), traj_c(:,1), 'g.');
    hold off;
    
    figure(1);
    hold on;
    plot(traj_c(:,2), traj_c(:,1), 'g.');
%     axis([traj_c(end,2)-20 traj_c(end,2)+20 traj_c(end,1)-20 traj_c(end,1)+20]);
    axis xy;
    hold off;
    
    pause(1.5);
end
    
    % sum(sum(cost_map-cost_map2))
    % sum(sum(cover_map-cover_map2))
    % sum(sum(elev_map-elev_map2))
    
    % range = 30;
    % cell_size = .1;
    % range_cell = ceil(ceil(2*range/cell_size)/4)+1;
    % kernal = single(ones(range_cell));
    %
    % map = rand(1000)-.25;
    % map = uint8(map);
    % % map(map<200) = 0;
    % map = single(map);
    %
    % tic;
    % val = conv2(map, kernal, 'same');
    % toc
