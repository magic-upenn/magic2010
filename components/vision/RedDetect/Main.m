% Display pixels that are red using only Cr channel (in YCbCr space),
% online. Adjust exposure to balance average luminance Y to setvalue.
% Also adjust target Y according to red bin score.
% Also estimate distance using stereo.
% A pixel is classified as red if above a Cr threshold. Cr threshold is 20
% points lower than maximum Cr value in image.
% Using Dan Lee's connected components MEX.

%profile on;

% FOV atand(44/72)*2=62.86 degrees
% angle = atand((xpixel-xcenter)/dist)

SetMagicPaths;

ipcInit;
imageMsgName = GetMsgName('Image');
staticOoiMsgName = GetMsgName('StaticOOI');
ipcAPIDefine(imageMsgName);
ipcAPIDefine(staticOoiMsgName);

%%%%%%%%%%%%%%%%%%

%savedir = '~/data/Hill_May31/';
figure(1);

% run this when changing to different camera:
%    bumblebeeWriteContextToFile('context.txt');

%Buildmap % Lookup table which converts quantized RGB color (4bit/channel) to YCbCr

%load CbCr.mat % Learned Gaussian of red color in YCbCr space
%lookupCbCr(200:end,:) = 1; % Threshold of red. Cr > 200 means very red.
%load Cr_params.mat % quadratic coefficients of Cr threshold vs exposure

load weighting.mat
weighting = weighting(1:2:end,1:2:end);

%%%%%%%%%%%%%%%%%%
bumblebeeInit;

bumblebeeStartTransmission;
libdc1394('videoGetSupportedModes');

libdc1394('printFeatureSet');

% adjust Exposure to meet a target average intensity of image
libdc1394('featureSetModeManual','Exposure');
libdc1394('featureSetValue','Exposure', 500);

maxdisp = 32;
init_stereo(maxdisp);

%%%%%%%%%%%%%%%%%%

damping_factor = 50; % for changing Exposure setpoints
targetY = 0.5;
score_hist = zeros(5,1);
counter = 0;
% tic
while(1)
    %for counter = 1:100
    counter = counter + 1;

    [yRaw,info,Exposure] = bumblebeeCapture;
    [yLeft, yRight] = bumblebeeRawToLeftRight(yRaw);
    [yRight,dispmap] = DoStereo(yLeft,yRight,maxdisp,0);

    %            [Y,Cb,Cr] = colorspace('rgb->YCbCr',yRight);
    notwhite = sum(yRight,3)<765;
    
    [Y,Cr] = Get_YCr_only(yRight);
    Ymod = Y.*weighting; % bottom of image weighted more than top
    Ymod = Ymod(notwhite(:));
    Ymean = mean(Ymod(:)/256)*2;

    Cr_threshold = max(190,max(Cr(:)) - 20);
    imCr_filt = Cr > Cr_threshold;
    %     BinIm = floor(double(yRight)/16)+1; % quantize RGB color to 4bits/channel
    %     mapind = sub2ind([16,16,16],BinIm(:,:,1),BinIm(:,:,2),BinIm(:,:,3)); % convert to YCbCr
    %     %Y = reshape(Ymap(mapind(:)),size(yRight,1),size(yRight,2)); % in image format
    %     Cb = reshape(Cbmap(mapind(:)),size(yRight,1),size(yRight,2));
    %     Cr = reshape(Crmap(mapind(:)),size(yRight,1),size(yRight,2));

    % create heatmap of probabilities of seeing red
    %     indices = sub2ind(size(lookupCbCr),round(Cr(:)),round(Cb(:)));
    %     imCr = reshape(lookupCbCr(indices),size(Cr));

    subplot(1,2,2);
    %    imagesc(dispmap); axis image;
    %     imagesc(imCr_filt); axis image;
    imagesc(Cr); axis image;

    %        subplot(1,3,3);
    %imCr_filt = bwareaopen(imCr_filt,20); % filter out small noisy patches

    %       imagesc(imCr_filt); axis equal;

    %    [Lred nred] = bwlabeln(imCr_filt);
    %    r = regionprops(Lred, 'BoundingBox','Extent');
    r = connected_regions(uint8(imCr_filt));

    r = r([r.area] >= 20);

    subplot(1,2,1);
    imshow(yRight);

    %     subplot(1,3,3);
    %     plot(Cb(:),Cr(:),'b.'); axis([0 250 40 250]);hold on;
    %     plotcov2(CbCr_mean,CbCr_cov,'conf',0.7,'plot-opts',{'Color', 'g', 'LineWidth', 1});

    % Calculate mean of boxes
    for i = 1:length(r)
        r(i).BoundingBox = [r(i).boundingBox(1,2) r(i).boundingBox(1,1) r(i).boundingBox(2,2)-r(i).boundingBox(1,2)+1 r(i).boundingBox(2,1)-r(i).boundingBox(1,1)+1];
        r(i).Extent = r(i).area/r(i).BoundingBox(3)/r(i).BoundingBox(4);
        Crcrop = imcrop(Cr,r(i).BoundingBox);
        r(i).Cr_mean = mean(Crcrop(:));
        %        Icrop = imcrop(BinIm,r(i).BoundingBox);
        %         mapind = sub2ind([16,16,16],Icrop(:,:,1),Icrop(:,:,2),Icrop(:,:,3)); % convert to YCbCr
        %         Cbcrop = reshape(Cbmap(mapind(:)),size(Icrop,1),size(Icrop,2));
        %         Crcrop = reshape(Crmap(mapind(:)),size(Icrop,1),size(Icrop,2));
        %        plot(Cbcrop(:),Crcrop(:),'r.');
        %
        %        r(i).CbCr_mean = mean([Cbcrop(:),Crcrop(:)]);
        %        r(i).CbCr_cov = cov([Cbcrop(:),Crcrop(:)]);
    end
    % Create a score for each red box
    hold on;
    for i = 1:length(r)
        mean_disp = mean(mean(imcrop(dispmap,round(r(i).BoundingBox)))); % ave disparity in bounding box
        r(i).distance = GetDistfromDisp(mean_disp); % in meters
        r(i).angle = atand((r(i).centroid(2)-256/2)/(72/44*256/2));
        [expected_xwidth,expected_yheight] = GetRedSizefromDist(r(i).distance); % [xwidth yheight] in pixels
        xwidth_score = exp(-(r(i).BoundingBox(3) - expected_xwidth)^2/(2*20^2));
        yheight_score = exp(-(r(i).BoundingBox(4) - expected_yheight)^2/(2*20^2));
        %shape_ratios = exp(-((r(i).BoundingBox(4)/r(i).BoundingBox(3)) - 1.4)^2/(2*0.5^2));
        %         KLdist =  exp(-(1/2*(CbCr_mean - r(i).CbCr_mean)*inv(r(i).CbCr_cov)*(CbCr_mean - r(i).CbCr_mean)' + ...
        %             + 1/2*log(det(r(i).CbCr_cov)/det(CbCr_cov)) + ...
        %             + 1/2*trace(CbCr_cov*inv(r(i).CbCr_cov)- eye(2)))/4);
        %redness = exp(-(r(i).Cr_mean-220)^2/(2*20^2));
        r(i).redbinscore = xwidth_score * yheight_score * r(i).Extent;% * redness; % Extent is redpixels/areaofbox

        if r(i).redbinscore > 0.5    % Display candidate red boxes
            linecolor = 'g';
        else
            linecolor = 'y';
        end
        line([r(i).BoundingBox(1),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2),r(i).BoundingBox(2)],'Color',linecolor);
        line([r(i).BoundingBox(1)+r(i).BoundingBox(3),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
        line([r(i).BoundingBox(1),r(i).BoundingBox(1)],[r(i).BoundingBox(2),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
        line([r(i).BoundingBox(1),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2)+r(i).BoundingBox(4),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
        text(r(i).BoundingBox(1),r(i).BoundingBox(2),sprintf('%2.2f',r(i).distance),'color','g');
        text(r(i).BoundingBox(1),r(i).BoundingBox(2)+r(i).BoundingBox(4),sprintf('%2.2f',r(i).angle),'color','g');
    end
    hold off;
    drawnow;

    if mod(counter,5)==0
        jpg = cjpeg(yRight);
        %%%%% send compressed jpg image through IPC %%%%%
        imPacket.id = str2double(getenv('ROBOT_ID'));
        imPacket.t  = GetUnixTime();
        imPacket.jpg = jpg;
        ipcAPIPublish(imageMsgName,serialize(imPacket));

        if ~isempty(r)
            [maxr,indr] = max([r.redbinscore]); % best red bin candidate
            if maxr > 0.5
                r = r(indr);
                r.id = str2double(getenv('ROBOT_ID'));
                r.t = GetUnixTime();
                %%%%% send struct r through IPC %%%%%
                ipcAPIPublish(staticOoiMsgName,serialize(r));
            end
        end
    end

    %%%% log images to disk
    %     imname = sprintf('%sred%08d_Exp%03d.jpg',savedir,counter,Exposure);
    %     print ('-djpeg', imname);
    %     rect_name = sprintf('%srect%08d_Exp%03d.jpg',savedir,counter,Exposure);
    %     imwrite(yRight,rect_name,'JPG');

    if length(r) >= 1
        curr_max_score = max([r.redbinscore]); % max is better than mean
    else
        curr_max_score = 0;
    end

    fprintf(1,'targetY %1.3f, Ymean %1.3f, score %1.3f, Exp_change %2.1f\n',targetY,Ymean,curr_max_score,damping_factor*(targetY-Ymean));
    % adjust exposure to keep Ymean near targetY
    if Ymean > targetY
        libdc1394('featureSetValue','Exposure', Exposure - max(1,round(damping_factor*(Ymean-targetY))));
    else
        libdc1394('featureSetValue','Exposure', Exposure + max(1,round(damping_factor*(targetY-Ymean))));
    end

    score_hist(1) = []; % keep a small history of red box scores
    score_hist(5) = curr_max_score;

    % adjust targetY to get better redbin score
    if counter > 5 % make sure score_hist has enough values in buffer
        curr_av_score = mean(score_hist);
        if curr_max_score > curr_av_score
            if targetY > Ymean
                targetY = targetY + 0.002;
            else
                targetY = targetY - 0.002;
            end
        else
            if targetY < Ymean
                targetY = targetY + 0.002;
            else
                targetY = targetY - 0.002;
            end
        end

        % if no good red regions then reset targetY
        if curr_av_score < 0.1
            targetY = 0.5;
        end
    end
end
% toc


bumblebeeStopTransmission;

%profile viewer
