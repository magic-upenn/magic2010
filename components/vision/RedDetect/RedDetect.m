function RedDetect
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

DEBUG = 0;

SetMagicPaths;
global POSE targetY
POSE.data = [];

LOGIMAGES = 0;

ipcInit;
imageMsgName = GetMsgName('Image');
staticOoiMsgName = GetMsgName('StaticOOI');
ipcAPIDefine(imageMsgName);
ipcAPIDefine(staticOoiMsgName);

ipcReceiveSetFcn(GetMsgName('Pose'), @PoseMsgHander);
ipcReceiveSetFcn(GetMsgName('CamParam'), @CamParamMsgHander);

%%%%%%%%%%%%%%%%%%

if LOGIMAGES
    savedir = '~/logimages/';
end
if DEBUG
    figure(1);
    subplot(1,3,1); handle1 = image([]); axis([1 256 1 192]); axis ij; axis equal;
    subplot(1,3,2); handle2 = image([]); axis([1 256 1 192]); axis ij; axis equal; axis off;
    subplot(1,3,3); handle3 = image([]); axis([1 256 1 192]); axis ij; axis equal; axis off;
end

% run this when changing to different camera:
%    bumblebeeWriteContextToFile('context.txt');

load weighting.mat
weighting = weighting(1:2:end,1:2:end);

%%%%%%%%%%%%%%%%%%
bumblebeeInit;

bumblebeeStartTransmission;
%libdc1394('videoGetSupportedModes');

%libdc1394('printFeatureSet');

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
    [Y,Cr] = Get_YCr_only(yRight);
    notwhite = sum(yRight,3)<765; % mask out completely white pixels
    Ymod = Y.*weighting; % bottom of image weighted more than top
    Ymod = Ymod(notwhite(:));
    Ymean = mean(Ymod(:)/256)*2;

    Cr_threshold = max(190,max(Cr(:)) - 20);
    imCr_filt = Cr > Cr_threshold;
if DEBUG
    set(handle3,'CData',dispmap); % update images on screen
    set(handle2,'CData',imCr_filt*255);

    subplot(1,3,1);
    imshow(yRight);
end
    r = connected_regions(uint8(imCr_filt));
    r = r([r.area] >= 20);

    % Calculate details of each red box candidate
    if DEBUG hold on; end
    for i = 1:length(r)
        r(i).BoundingBox = [max(1,r(i).boundingBox(1,2)) max(1,r(i).boundingBox(1,1)) r(i).boundingBox(2,2)-r(i).boundingBox(1,2)+1 r(i).boundingBox(2,1)-r(i).boundingBox(1,1)+1];
        r(i).Extent = r(i).area/r(i).BoundingBox(3)/r(i).BoundingBox(4);
        Crcrop = imcrop(Cr,r(i).BoundingBox);
        r(i).Cr_mean = mean(Crcrop(:));

        %mean_disp = mean(mean(imcrop(dispmap,round(r(i).BoundingBox)))); % ave disparity in bounding box
        BB = r(i).BoundingBox;
        temp = zeros(size(imCr_filt)); % temp will store red pixels inside bounding box
        temp(BB(2):BB(2)+BB(4)-1,BB(1):BB(1)+BB(3)-1) = imCr_filt(BB(2):BB(2)+BB(4)-1,BB(1):BB(1)+BB(3)-1);
        mean_disp = mean(dispmap(logical(temp))); % ave disparity in red pixels in bounding box
        %    fprintf(1,'mean_disp %2.3f\n',mean_disp);
        r(i).distance = GetDistfromDisp(mean_disp); % in meters
        r(i).angle = atand((r(i).centroid(2)-256/2)/(72/44*256/2));

        % filter out by expected size of red bin
        cropImCr = imcrop(imCr_filt,r(i).BoundingBox);
        [MajorLen,MinorLen] = GetMajorLengths(cropImCr); % get dimensions of bin in image which could be rotated
        [expected_xwidth,expected_yheight] = GetRedSizefromDist(r(i).distance); % [xwidth yheight] in pixels. From distance estimate
        if MinorLen > 0.66*expected_xwidth && MinorLen < 1.33*expected_xwidth
            xwidth_score = 1;
        else
            xwidth_score = 0;
        end
        if MajorLen > 0.66*expected_yheight && MajorLen < 1.33*expected_yheight
            yheight_score = 1;
        else
            yheight_score = 0;
        end
        r(i).redbinscore = xwidth_score * yheight_score * r(i).Extent;% Extent is redpixels/areaofbox

        if DEBUG
        linecolor = 'g';
        if r(i).redbinscore > 0.5    % Display candidate red boxes
            line([r(i).BoundingBox(1),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2),r(i).BoundingBox(2)],'Color',linecolor);
            line([r(i).BoundingBox(1)+r(i).BoundingBox(3),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
            line([r(i).BoundingBox(1),r(i).BoundingBox(1)],[r(i).BoundingBox(2),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
            line([r(i).BoundingBox(1),r(i).BoundingBox(1)+r(i).BoundingBox(3)],[r(i).BoundingBox(2)+r(i).BoundingBox(4),r(i).BoundingBox(2)+r(i).BoundingBox(4)],'Color',linecolor);
            text(r(i).BoundingBox(1),r(i).BoundingBox(2),sprintf('%2.2f',r(i).distance),'color','g');
            text(r(i).BoundingBox(1),r(i).BoundingBox(2)+r(i).BoundingBox(4),sprintf('%2.2f',r(i).angle),'color','g');
        end
        end
    end

    if DEBUG    hold off;
    drawnow;
end

    %%%% send images and OOI to vision GUI console through IPC %%%%%
    ipcReceiveMessages;

    if mod(counter,2)==0
        jpg = cjpeg(yRight);
        %%%%% send compressed jpg image through IPC %%%%%
        imPacket.id = str2double(getenv('ROBOT_ID'));
        imPacket.t  = GetUnixTime();
        imPacket.jpg = jpg;
        imPacket.Ymean = Ymean;
        imPacket.POSE = POSE.data;
        ipcAPIPublish(imageMsgName,serialize(imPacket));

        if ~isempty(r) && counter > 20
            [maxr,indr] = max([r.redbinscore]); % best red bin candidate
            if maxr > 0.5
                counter = 0;
                r = r(indr);
                OOIpacket.OOI = r;
                %  add POSE.data
                OOIpacket.id = str2double(getenv('ROBOT_ID'));
                OOIpacket.t = GetUnixTime()
                if ~isempty(POSE.data)
                    OOIpacket.POSE = POSE.data;
                else
                    OOIpacket.POSE = [];
                end
                %%%%% send struct r through IPC %%%%%
                ipcAPIPublish(staticOoiMsgName,serialize(OOIpacket));
                if LOGIMAGES
                   imagename = sprintf('%simage%08d.jpg',savedir,counter);
                   imwrite(yRight,imagename,'JPG');
                end
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%% log images to disk
    %     imname = sprintf('%sred%08d_Exp%03d.jpg',savedir,counter,Exposure);
    %     print ('-djpeg', imname);
    %     rect_name = sprintf('%srect%08d_Exp%03d.jpg',savedir,counter,Exposure);
    %     imwrite(yRight,rect_name,'JPG');
    %%%%%%%%%%%%%%%%%%%%%%%


    if length(r) >= 1
        curr_max_score = max([r.redbinscore]); % max is better than mean
    else
        curr_max_score = 0;
    end

if DEBUG    fprintf(1,'targetY %1.3f, Ymean %1.3f, score %1.3f, Exp_change %2.1f\n',targetY,Ymean,curr_max_score,damping_factor*(targetY-Ymean));
end
% adjust exposure to keep Ymean near targetY
    if Ymean > targetY
        libdc1394('featureSetValue','Exposure', Exposure - max(1,round(damping_factor*(Ymean-targetY))));
    else
        libdc1394('featureSetValue','Exposure', Exposure + max(1,round(damping_factor*(targetY-Ymean))));
    end

    score_hist(1) = []; % keep a small history of red box scores
    score_hist(5) = curr_max_score;

    % adjust targetY to get better redbin score
    %     if counter > 5 % make sure score_hist has enough values in buffer
    %         curr_av_score = mean(score_hist);
    %         if curr_max_score > curr_av_score
    %             if targetY > Ymean
    %                 targetY = targetY + 0.002;
    %             else
    %                 targetY = targetY - 0.002;
    %             end
    %         else
    %             if targetY < Ymean
    %                 targetY = targetY + 0.002;
    %             else
    %                 targetY = targetY - 0.002;
    %             end
    %         end

    % if no good red regions then reset targetY
    %        if curr_av_score < 0.1
    %            targetY = 0.5;
    %        end
    %    end
end
% toc


bumblebeeStopTransmission;

%profile viewer

function PoseMsgHander(data,name)
global POSE
POSE.data = [];
if isempty(data)
    return;
end

POSE.data = MagicPoseSerializer('deserialize',data);

function CamParamMsgHander(data,name)
global targetY
if isempty(data)
    return;
end

targetY = deserialize(data);
