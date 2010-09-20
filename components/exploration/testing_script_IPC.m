 traj_c = [];

 [cover_map cost_map elev_map] = inputM('ModCombinedMap3.txt');
figure(32);
image(cost_map);
title('original cost map');
axis equal

figure(33);
image(elev_map);
title('original elev map');
axis equal

for rep=1:1
    
    
    [cover_map2 inf_cost_map2 elev_map2] = inputM('Map_out.txt');
    5
    figure(1);
    image(inf_cost_map2);
    title('post cost');
    axis equal
    
%     figure(4);
%     image(cover_map2);
%     title('coverage out');
%     axis equal
    
    [djikstra] = input_djikstra('Map_extra.txt');
    figure(35);
    djikstra(djikstra==100000000) = 10000;
    image(70*double(djikstra)/double(max(max(djikstra))));
    title('djikstra');
    axis equal
    
    [score, traj] = input_mapMST('Map_traj.txt');
    traj = (reshape(traj,8, []))';
    traj = traj(:,1:2);
    traj_c = vertcat(traj_c, traj);
    figure(1);
    hold on;
    plot(traj_c(:,2), traj_c(:,1), 'g.');
    hold off;
%     axis([traj_c(end, 2)-30 traj_c(end,2)+30 traj_c(end,1)-30 traj_c(end,1)+30]);
    
    traj_c = unique(traj_c, 'rows')
    pause(.75);
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
