% CIS580 Spring 2010 HW4 
% stereo_matching.m
%  
function [yaw] = yaw_match(first,second,yaw_range)
% Inputwpixel_range
%   left_file_name, right_file_name  : left and right input image file
%   disparity_range                  : disparity search range, [min max]
%
% Output:
%   disparity                        : Left disparity map
%   confidence                       : Left confidence map


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write your own stereo matching function here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WINDOWSIZE = 7;
%first = rgb2gray(first);
%second = rgb2gray(second);
%min_disp = yaw_range(1);
%max_disp = yaw_range(2);
%final = uint8(zeros(size(first)));
%left = double(rgb2gray(imread(left_file_name)));
%right = double(rgb2gray(imread(right_file_name)));
%[numrows_l,numcols_l] = size(left);
%disparity = zeros(numrows_l, numcols_l);
%first = bsxfun(@rdivide,first,max(max(first)));
%second = bsxfun(@rdivide,second,max(max(second)));
[row col thi] = size(first);
V = zeros(size(yaw_range));
V1 = zeros(size(yaw_range));
bar1_min = 83;
bar1_max = 107;
bar2_min = 443;
bar2_max = 467;
%confidence = zeros(row, col);
%sad = zeros(size(yaw_range));
% for i = 1+p:numrows_l-p
%   for j = 1+p:numcols_l-p
      %prev = zeros(row,col)-100000000; %infinity
      %best=zeros(row,col)+ yaw_range(1);
      %mat=zeros(numrows_l,numcols_l);
      %ssd=zeros(numrows_l,numcols_l);
      %sad=zeros(numrows_l,numcols_l);
      %ncc=zeros(row,col);
      for k = 1:numel(yaw_range)
          disp = yaw_range(k);
          %if(disp > 0) % shift the image
            %final(:,1+disp:col,:) = first(:,1:col-disp,:);
            %final(:,1:disp,:) = first(:,col-disp+1:co,:); 
            %final = circshift(first,[0 disp]);
          %elseif(disp <0)
            %final(:,1:col+disp,:) = first(:,-(disp)+1:col,:);
            %final(:,(col+1)+disp:col,:) = first(:,1:-disp,:);
            final = circshift(first,[0 disp]);
          %else
           %   final = first;
          %end
%           if disp~=0
%               mat(:,(disp+1):numcols_l)=left(:,(disp+1):numcols_l)...
%                   -right(:,1:numcols_l-(disp));
%               
%           else
%               mat=left-right;
%           end
          mat = (final - second);
          %Removing the bars from the image
          mat(:,bar1_min:bar1_max,:) = 0;
          mat(:,bar2_min:bar2_max,:) = 0;
%           figure;
%           subplot(1,2,1)
%           imagesc(abs(mat))
%           subplot(1,2,2)
%           imagesc(mat.^2)
          % for the normal summing of all costs
          %sum of squared differences
          %ssd = conv2(mat.^2,ones(WINDOWSIZE),'same');
          %ssd = mat.^2;
          %V(k) = sum(ssd(:));
          V(k) = sum(abs(mat(:)));
          %V1(k) = sum(mat(:).^2);
          
          %sum of absolute differences
          
          %sad=conv2(abs(mat),ones(WINDOWSIZE,WINDOWSIZE),'same');
          %sad(k) = sum(mat(:));
          %gaussian kernel
          %ssd = conv2(mat.^2,fspecial('gaussian',WINDOWSIZE,3),'same');
          %sum of absolute differences
           %sad=conv2(abs(mat),fspecial('gaussian',WINDOWSIZE,3),'same');
            
%            il = mean(mean(second));
%            ir = mean(mean(final));
%            ill= second - il;
%            irr= final - ir;
           %nccnum = conv2(ill.*irr,ones(WINDOWSIZE,WINDOWSIZE),'same');
           %nccden =
           %((conv2(ill.*ill,ones(WINDOWSIZE,WINDOWSIZE),'same')).^0.5 .* (conv2(irr.*irr,ones(WINDOWSIZE,WINDOWSIZE),'same')).^0.5);
           %ncc=nccnum./nccden;
           %ncc = (ill.*irr)/(
% %           ssd = 0.0;
% %           if j+p-disp > 0
% %           ssd=sum(sum((left(i+p:i-p,j+p:j-p)-right(i+p:i-p,j+p-disp:j-p-disp)).^2));
% %           else
% %           ssd=inf;
% %           end
%           %c=(prev>ssd);
%           %c=(prev>sad);
           %c=(prev<ncc);
%           %prev=imcomplement(c).*prev+c.*ssd;
           %prev=imcomplement(c).*prev+c.*ncc;
           %best=imcomplement(c).*best+c.*disp; 
      end
%      figure;
%      subplot(1,2,1)
%     plot(1:numel(V),V);
%     subplot(1,2,2)
%     plot(1:numel(V1),V1);
    %[a,b] = hist(best(:),min(best(:)):max(best(:)));
    [val,id] = min(V);    
    %val = max(a);
    yaw = yaw_range(id)*(2*pi)/720; % 720 here is the basis for saying how much degree each column of the image subtends
    %yaw = -val*(2*pi)/col;
end
%   end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAD with fixed window size version, mex-C implementation
% You don't have to understand this part, it's just a sample

% stereo_weight   = [1 1 1];  % Stereo matching weight for each channel
% stereo_window   = 11;       % Stereo matching window size
% 
% I1 = double(imread(left_file_name));
% I2 = double(imread(right_file_name));
% [disparity, confidence] = stereo_matching_c(I2, I1, -disparity_range(2), disparity_range(1), stereo_window, stereo_weight);
%disparity = -disparity;