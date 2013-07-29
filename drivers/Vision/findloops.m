function loops = findloops(bw)
%this function finds all lopps in a binary image, bw
j = 1;
B = bwboundaries(bw, 8, 'noholes');
minpixcnt = 200;
loops = {};
for i=1:length(B)
    
    cur = B(i);
    len = length(cur{1});
    %filter out short connected components
    if len < minpixcnt
        continue;
        fprintf('too short');
    end
    
    start = cur{1}(1,:);
    finish = cur{1}(end,:);
    %check if last pixel is equal to the start pixel
    if start == finish
        [els numU] = count_unique(cur{1})
        if length(els) < len*.5
            continue
        else
        
        
        
%         cnt = 1;
%         while (cur{1}(1+cnt,:) == cur{1}(end-cnt,:))
%             if cnt < length(cur{1})/2
%                 cnt=cnt+1
%             else
%                 break;
%             end
%         end
%         if cnt > 10
%             continue;
%         elseif cnt< 10
            fprintf('entered if\n')
            loops(j) = cur;
            j = j+1;
         end
    end
    
end
%% plot the loops
figure;
for i=1:length(loops)
    hold on;
    cur_loop = loops{i};
    plot(cur_loop(:,2), cur_loop(:,1), 'b', 'LineWidth', 2);
end
end