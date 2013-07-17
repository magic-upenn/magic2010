function outstruct = ManualPointsSelectionCornerAutoCalibGUI(ImageDataIn, handles)

N=length(ImageDataIn);

%% Configurations
GETMOREPOINTS = 0;
CALIBMETHOD=1;
ImageData=ImageDataIn;

%% Select the corners to add
cancel = 0;
for i=1:1:N
%     try
    [points plane cancel GETMOREPOINTS changed] = ManualPointSelectionCorner(ImageDataIn(i));
    ImageData(i).PosImage = [points; ones(1,length(points))];
    ImageData(i).PosPlane = [plane; ones(1,length(points))];
    ImageData(i).PosImageAuto = [points; ones(1,length(points))];
    ImageData(i).PosPlaneAuto = [plane; ones(1,length(points))];
  
    if changed || GETMOREPOINTS
        %Get additional points
        if GETMOREPOINTS
            % First linear calibration with automatically detected points
            ImageData(i).InitCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,CALIBMETHOD);
            ImageData(i).InitCalib.ReProjError=ReProjectionError(ImageData(i).InitCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
            disp(sprintf('Inital calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
                ImageData(i).InitCalib.qsi,ImageData(i).InitCalib.eta,ImageData(i).InitCalib.focal,ImageData(i).InitCalib.center(1),...
                ImageData(i).InitCalib.center(2), ImageData(i).InitCalib.skew,ImageData(i).InitCalib.aratio))
            
            % Get More Points
            ImgStruct=struct('Info',ImageData(i).Info,'ImageGray',ImageData(i).ImageGray,'Conic',ImageData(i).Boundary);
            [ImageData(i).PosPlane, ImageData(i).PosImage]=GetMorePoints(ImgStruct,ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
            disp(sprintf('Image %d has generated %d more points',i,length(ImageData(i).PosPlane)-length(ImageData(i).PosPlaneAuto)))
        end
        
        % Re-calibrate using the linear method
        ImageData(i).FinalCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,CALIBMETHOD);
        ImageData(i).FinalCalib.ReProjError=ReProjectionError(ImageData(i).FinalCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
        fprintf('Final calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
            ImageData(i).FinalCalib.qsi,ImageData(i).FinalCalib.eta,ImageData(i).FinalCalib.focal,ImageData(i).FinalCalib.center(1),...
            ImageData(i).FinalCalib.center(2), ImageData(i).FinalCalib.skew,ImageData(i).FinalCalib.aratio)
    end
%     %Recount the corners
%     if length(points)~=length(ImageData(i).PosPlane)
%         [PosImageAuto PosPlaneAuto] = RecountCorners (ImageData(i).ImageGray, points, ImageData(i));
%         ImageData(i).PosImageAuto = [transpose(PosImageAuto); ones(1,length(PosImageAuto))];
%         ImageData(i).PosPlaneAuto = [transpose(PosPlaneAuto); ones(1,length(PosPlaneAuto))];
%         
%         CALIBMETHOD=1;
%         % First linear calibration with automatically detected points
%         ImageData(i).InitCalib=SingleImgCalibration(ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto,CALIBMETHOD);
%         ImageData(i).InitCalib.ReProjError=ReProjectionError(ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
%         disp(sprintf('Inital calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
%             ImageData(i).InitCalib.qsi,ImageData(i).InitCalib.eta,ImageData(i).InitCalib.focal,ImageData(i).InitCalib.center(1),...
%             ImageData(i).InitCalib.center(2), ImageData(i).InitCalib.skew,ImageData(i).InitCalib.aratio))
%         
%         % Get additional points
%         ImgStruct=struct('Info',ImageData(i).Info,'ImageGray',ImageData(i).ImageGray,'Conic',ImageData(i).Boundary);
%         [ImageData(i).PosPlane, ImageData(i).PosImage]=GetMorePoints(ImgStruct,ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
%         disp(sprintf('Image %d has generated %d more points',i,length(ImageData(i).PosPlane)-length(ImageData(i).PosPlaneAuto)))
%         
%         
%         % Re-calibrate using the linear method
%         ImageData(i).FinalCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,CALIBMETHOD);
%         ImageData(i).FinalCalib.ReProjError=ReProjectionError(ImageData(i).FinalCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
%         disp(sprintf('Final calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
%             ImageData(i).FinalCalib.qsi,ImageData(i).FinalCalib.eta,ImageData(i).FinalCalib.focal,ImageData(i).FinalCalib.center(1),...
%             ImageData(i).FinalCalib.center(2), ImageData(i).FinalCalib.skew,ImageData(i).FinalCalib.aratio))    
%     end
%     catch
%        warndlg('Input Error');
%        WriteMatResults(ImageData,handles.ARTHRODIR);
%     end

    if cancel
        break
    end
end

outstruct = ImageData;

