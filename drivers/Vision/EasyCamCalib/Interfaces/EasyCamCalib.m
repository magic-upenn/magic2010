function varargout = EasyCamCalib(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @EasyCamCalib_OpeningFcn, ...
    'gui_OutputFcn',  @EasyCamCalib_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);

if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT ABOVE THIS


function EasyCamCalib_OpeningFcn(hObject, eventdata, handles, varargin)
%Choose default command line output for EasyCamCalib
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% clc;
fff=which('EasyCamCalib');
[s d dd] = fileparts(fff);
ind = find(double(s)==double(filesep));
handles.PROJECTPATH = s(1:ind(end));
addpath(sprintf('%s%sInterfaces',handles.PROJECTPATH,filesep));
addpath(sprintf('%s%sInterfaces%sBinInterfaces',handles.PROJECTPATH,filesep,filesep));
Paths(handles.PROJECTPATH);     %Adds all the necessary paths

%Global variables
handles.caliblist = {};         %Used in "File-mode". Contains the name of the images
handles.caliblistpath = {};     %Used in "File-mode". Contains the full path of the images
handles.ImageData = [];         %Main data structure used to store the images, calibration, conic, additional information, etc...
handles.ISARTHROSCOPIC = 1;     %Indicates if the image is arthroscopic or not
handles.REFINEMENT = 0;         %Indicates if we want to refine the intrinsics
handles.HANDEYE = 0;            %Indicates if we want to compute the HandEye transform
handles.HANDEYEREFINEMENT = 0;  %Indicates if we want to refine the HandEye transform
handles.CHANGEORIGINS = 0;      %Indicates if we want to automatically change the origin of the grids
handles.LISTMODE = 0;           %Mode of the file list chooser. 0 - File mode, 1 - matlab data mode
handles.FROMARTHROSYNC = 0;     %This variable is set to 1 if AutoCaligGUI is called from ArthroSync
handles.OPTIMALCALIBRATION = 0; %This variable is set to 1 if the Optimal calibration (calibration refined) is present in the ImageData structure
handles.switchCOORDINATES = 0;
handles.switchPOSIMAGEAUTO = 0;
handles.switchPOSIMAGE = 1;
handles.switchBOUNDARY = 0;
handles.switchINITCALIB = 0;
handles.switchFINALCALIB = 0;
handles.switchOPTIMCALIB = 0;
handles.switchBLAMEPOINTS = 0;
handles.switchHANDEYE = 0;
handles.switchHANDEYEREFINED = 0;
handles.dispVALUES = 1;
handles.MANUAL = 1;
handles.PROCEED = 0;
handles.OPENEDOPTIONS = 0;
set(handles.pushbutton_value,'BackgroundColor',[233 138 62]./255);
set(handles.pushbutton_rotate,'BackgroundColor',[233 138 62]./255);
handles.showOPT = 1;            %Display results. 0 - InitCalib; 1 - FinalCalib; 2 - Optimcalib
handles.ARTHRODIR = sprintf('%stemp%s',handles.PROJECTPATH,filesep);
set(handles.repbar,'Visible','off');
handles.barhandler = 0;
handles.CurrentInd=1;
handles.dirtosavecalib = '';
handles.DISCARDFAIL=1;
handles.ABORTONIMAGEFAILURE=1;
handles.autotrans=0;
handles.rotate=1;
handles.zoom=0;

%Starting Functions
handles.defaultOptionsPath=sprintf('%stemp%sdefaultOptions.mat',handles.PROJECTPATH,filesep);
loadOptions(hObject, handles);
handles=guidata(hObject);
ClearImages(handles,1,0);
SwitchMode(hObject, eventdata, handles);


%Necessary for arthrosync module (needs validation)
initial_dir = handles.PROJECTPATH;
if nargin > 4
    if strcmpii(varargin{1},'dir')
        if exist(varargin{2},'dir')
            initial_dir = varargin{2};
        else
            errordlg('Input argument must be a valid directory','Input Argument Error!')
            return
        end
    elseif strcmpii(varargin{1},'ARTHROSYNC')
        if ischar(varargin{2})
            StartByARTHROSYNC(hObject, eventdata, handles, varargin{2}, varargin{3}, varargin{4});
            return
        else
            errordlg('Input argument must be a valid directory','Input Argument Error!')
            return
        end
    else
        errordlg('Unrecognized input argument','Input Argument Error!');
        return;
    end
end

%Fill the listbox with the directory content
load_listbox(initial_dir,handles)




function varargout = EasyCamCalib_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
guidata(hObject, handles);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% MAIN FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pushbutton_start_Callback(hObject, eventdata, handles)
clc
handles.OPENEDOPTIONS=getappdata(0,'OPENEDOPTIONS');
if handles.OPENEDOPTIONS 
    fprintf('Loading user-defined options from the OptionsGUI.\n');
    updateOptions (hObject, handles);
end
handles = guidata(hObject);

OBJECTNUMBER=2;             %For optotracker hand eye procedure
WHEREISARTHROSCOPE=1;       %For optotracker hand eye procedure
BOUNDARYITERNUMBER=5;       %Iterations to detect the endoscopic boundary
CALIBMETHOD=1;              %Calibration method (1 or 2)
REFINEMENTDIVISIONMODEL=1;  %Order of the division model taken in the optimization step (1 or 2)
HANDEYEMETHOD=4;            %HandEye computation method: 1-ModifiedDQ; 2-Classic; 3-ModifiedDQRansac; 4-NewClassic
HANDEYEFILTER=[0 1 1 0];    %Filters for HandEye refinement: [inconsistent_rotations small_rotation parallel_rotation_axes small_motions]

% Control check for empty list
if length(handles.caliblistpath)<1
    disp('No images in the calibration list. Nothing to be done...')
    warndlg('No images in the calibration list. Use the directory list to insert some image sin the calibration list.','No Images')
    return
end
% Do not process if we are in listmode
if handles.LISTMODE
    return
end

% Display calibration information before we start
ImageDataLoader (hObject, handles, handles.caliblistpath{1}, 1);
handles = guidata(hObject);
setappdata(0,'RESOLUTION',handles.ImageData(1).Info.Resolution);
setappdata(0,'NUMBEROFIMAGES',length(handles.caliblistpath));
info=Info();
waitfor(info);
handles.PROCEED=getappdata(0,'PROCEED');
if(~handles.PROCEED)
    disp('Calibration canceled.')
    return
end

% Start the calibration
handles.ImageData = [];
badcount = [];           
i=1;
for k=1:length(handles.caliblistpath)
    
    failed=0;
    handles=FillWithNull(handles,1,i);
    
    % ImageData Loader
    try
        if ~failed
            change_state(handles,'Loading Data')
            disp(sprintf('Filepath is: %s',handles.caliblistpath{k}));
            ImageDataLoader (hObject, handles, handles.caliblistpath{k}, i);
            handles = guidata(hObject);
        end
    catch
        fprintf('WARNING: Calibration failed while loading the image data.\n');
        failed=1;
        levelfail=1;
    end
  
    % Boundary Detection
    try
        if ~failed
                change_state(handles,'Computing Boundary');
            DetectBoundary(hObject, handles, BOUNDARYITERNUMBER, i);
            handles = guidata(hObject);
            showResutltsGUI(hObject,handles,i,'boundarydetection');
        end
    catch
        fprintf('WARNING: Calibration failed while detecting the boundary.\n');
        failed=1;
        levelfail=2;
    end
 
    % AutoCornerDetection
    try
        if ~failed
                change_state(handles,'Auto Corner Detection')
            AutoCornerFinder(hObject, handles, i);
            handles=guidata(hObject);
            showResutltsGUI(hObject,handles,i,'autocornerfinder');
        end
    catch
        fprintf('WARNING: Calibration failed while detecting the grid corners.\n');
        failed=1;
        levelfail=3;
    end
    
    % First linear calibration with automatically detected points
    try
        if ~failed
            change_state(handles,'Initial Calibration')
            FirstLinearCalib(hObject,handles, CALIBMETHOD,i);
            handles=guidata(hObject);
            showResutltsGUI(hObject,handles,i,'firstcalib');
        end
    catch
        fprintf('WARNING: Calibration failed while computing the first calibration.\n');
        failed=1;
        levelfail=4
    end
    
    % Get additional points
    try
        if ~failed
            change_state(handles,'Generating more points')
            GetAdditionalPoints(hObject,handles,i);
            handles=guidata(hObject);
            showResutltsGUI(hObject,handles,i,'generatedpoints');
        end
    catch
        fprintf('WARNING: Calibration failed while generating more points.\n');
        failed=1;
        levelfail=5;
    end
    
    % Re-calibrate using the linear method
    try
        if ~failed
            change_state(handles,'Final Calibration')
            SecondLinearCalib(hObject,handles,CALIBMETHOD,i);
            handles=guidata(hObject);
            showResutltsGUI(hObject,handles,i,'secondcalib');
        end
    catch
        fprintf('WARNING: Calibration failed computing the second calibration.\n');
        failed=1;
        levelfail=6;
    end
   
    
    if failed
        FillWithNull(handles,levelfail,i);
        badcount=[badcount i];
        if handles.ABORTONIMAGEFAILURE
            disp('WARNING: Calibration Failed, aborting...')
            return
        end
    end
    i=i+1;
end

if length(badcount)>0 && handles.DISCARDFAIL
    p=1;
    auxstruct=[];
    index=setdiff(1:length(handles.caliblistpath),badcount);
    for j=index
        auxstruct.ImageData(p)=handles.ImageData(j);
        p=p+1;
    end
    clear handles.ImageData
    handles.ImageData=auxstruct.ImageData;
end
handles.showOPT=1;
set(handles.radiobutton_showfinal,'Value',1);
handles.CurrentInd=1;
change_state(handles,1)


% Redefine the origins of the generated points (automatically)
if handles.CHANGEORIGINS
    try
    %Automatically save the data into a temp file
    WriteMatResults(handles.ImageData,handles.ARTHRODIR);
    change_state(handles,'Changin Calibration Grid Origins')
    disp('Changing reference frames of the calibration grid coordinates')
    for i=1:length(handles.ImageData)
        try
            [Pimg_o Pimg_d Pplane_o Pplane_d] = ChangeOriginAuto(handles.ImageData(i),0);
            if ~isempty(Pimg_o) && ~isempty(Pimg_d) && ~isempty(Pplane_o) && ~isempty(Pplane_d)
                %compute the transform to the new grid frame
                I =  Pplane_d - Pplane_o ;
                I = I/norm(I);
                J = cross([0 0 1],I);
                T=[I(1:2) J(1:2)' Pplane_o(1:2);0 0 1] ;
                T = inv(T) ;
                origin = T * Pplane_o ;
                OX = T * Pplane_d ;
                T_old = handles.ImageData(i).FinalCalib.T;
                T_old2new = [I J' [0;0;1] [Pplane_o(1:2);0] ; 0 0 0 1];
                T_new = T_old * T_old2new;
                handles.ImageData(i).PosPlane(:,:) = T * handles.ImageData(i).PosPlane(:,:);
                handles.ImageData(i).FinalCalib.T = T_new;
            else
                display('WARNING!!! Calibration Grid marks not found...')
            end
        catch
            fprintf('Error changing reference fram of image %d \n',i)
        end
    end
    catch
        disp('WARNING: Failed during automatic origins change.')
    end
end

% Calibration refinement
if handles.REFINEMENT
    try
        %Automatically save the data into a temp file
        WriteMatResults(handles.ImageData,handles.ARTHRODIR);
        change_state(handles,'Refinning Calibration Parameters')
        disp('Refinning the calibration parameters')
        handles.ImageData = RefineCalibrationAutoCalibGUI(handles.ImageData,REFINEMENTDIVISIONMODEL);
        handles.showOPT=2;
        DisplayResults(handles,1,handles.showOPT);
        DisplayRepError(handles,handles.showOPT,handles.dispVALUES);
        dirlist_Callback(hObject, eventdata, handles);
        %Write Results to file
        if handles.FROMARTHROSYNC
            WriteResults(0,handles);
        end
    catch
        disp('WARNING: Calibration refinement failed.')
    end
end

%Hand-Eye calibration
if handles.HANDEYE & length(handles.ImageData)>=3
    %Automatically save the data into a temp file
    WriteMatResults(handles.ImageData,handles.ARTHRODIR);
    change_state(handles,'Computing HandEye Calibration')
    disp('Computing HandEye calibration')
    handles.ImageData = HandEyeCalibrationAutoCalibGUI (handles.ImageData,HANDEYEMETHOD,HANDEYEFILTER);
    %Write Results to file
    if handles.FROMARTHROSYNC
        WriteResults(1,handles);
    end
end

%Write Results to file
if handles.FROMARTHROSYNC
    WriteResults(2,handles);
    WriteResults(3,handles);
end

%Automatically save the data into a temp file
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
handles=guidata(hObject);
change_state(handles,'Done')

%Issue a warning if any image failed
if length(badcount)>0
    if isempty(handles.ImageData)
        h1 = warndlg('None of the images on the calibration list were calibrated', 'Error');
    else
        str='Warning, image(s) ';
        for p=1:length(badcount)
            str = [str sprintf('%d, ',badcount(p))];
        end
        str=[str 'were not correctly processed. Run the manual selection tool to correct or eliminate them from the list.'];
        h1=warndlg(str,'Warning');
    end
end
guidata(hObject, handles);



%% Support Function
function ImageDataLoader (hObject, handles, imagepath, i)
handles.ImageData(i).ImageRGB = imread(imagepath);
handles.ImageData(i).ImageGray = rgb2gray(handles.ImageData(i).ImageRGB);
handles.ImageData(i).Info.GridSize = handles.GRIDSIZE;
handles.ImageData(i).Info.IsArthroscopic = handles.ISARTHROSCOPIC;
handles.ImageData(i).Info.Resolution = size(handles.ImageData(i).ImageRGB);
% [OptoR OptoT] = LoadOptoInfoSingle(handles.caliblistpath{k}, OBJECTNUMBER, WHEREISARTHROSCOPE);
% if ~isempty(OptoR)
%     handles.ImageData(i).Hand2Opto = [OptoR OptoT';0 0 0 1];
% end
handles.ImageData(i).Boundary = [];
guidata(hObject, handles);

function change_state(handles, str)
set(handles.state, 'String',str);
drawnow

function DetectBoundary(hObject, handles, iter, i)
if handles.ISARTHROSCOPIC
    AngleStep=1*pi/180;
    RansacThreshold=0.05;
    m=handles.ImageData(i).Info.Resolution(1);
    n=handles.ImageData(i).Info.Resolution(2);
    z=min(m,n);
    C = [n/2 m/2];
    MajorAxis=z/2.1;
    MinorAxis=z/2.1;
    N = 9;
    RadiusRange=round(n/15);
    if(~mod(RadiusRange,2))
        RadiusRange=RadiusRange+1;
    end
    phi=-1.45;
    
    % Find the Conic
    for j=1:1:iter
        
        % Affine homography that maps the conic into a circle with radius MinorAxis
        H=[cos(-phi) sin(-phi) 0;-sin(-phi) cos(-phi) 0; 0 0 1]*...
            diag([MinorAxis/MajorAxis 1 1])*...
            [cos(phi) sin(phi) 0;-sin(phi) cos(phi) 0; 0 0 1]*...
            [1 0 -C(1);0 1 -C(2); 0 0 1];
        
        % Generate interpolated image
        [imRadial,theta,rho]=CD_GenerateRadialImg(handles.ImageData(i).ImageGray,H,MinorAxis,RadiusRange,AngleStep);
        Points=CD_DetectContourInRadialImg(imRadial,theta,rho,H,N,0,0);
        Pointstotal = Points;
        
        % Restimate the conic
        [omega, inliers] = CD_conic_ransac (Points(1:2,:), 5,RansacThreshold);
        Points=Pointstotal(:,inliers);
        
        % Compute Conic Parameters
        Omega=[omega(1) omega(2) omega(4);omega(2) omega(3) omega(5);omega(4) omega(5) omega(6)];
        [C,Vertex,MajorAxis,MinorAxis,phi]=CD_ComputeConicParameters(Omega);
    end
    
    % Generate interpolated image for lent mark detection
    [imRadial2,theta,rho,X,Y]=CD_GenerateRadialImg(handles.ImageData(i).ImageGray,H,MinorAxis,RadiusRange,AngleStep);
    
    % Find the lent mark position
    lensangleplot = CD_FindLentMark(imRadial2,8);
    lensangle = (360-lensangleplot)+180;
    if(lensangle<0 || lensangle>360)
        lensangle = -1*sign(lensangle)*360 + lensangle;
    end
    lensangleimage=inv(H)*[MinorAxis*cos((360-lensangle)*pi/180); MinorAxis*sin((360-lensangle)*pi/180);1];
    if(lensangleimage(1)>n), lensangleimage(1)=n; end
    if(lensangleimage(1)<1), lensangleimage(1)=1; end
    if(lensangleimage(2)>m), lensangleimage(2)=m; end
    if(lensangleimage(2)<1), lensangleimage(2)=1; end
    
    % Fill the ImageData Structure
    handles.ImageData(i).Boundary.Points = Points;
    handles.ImageData(i).Boundary.Omega = Omega;
    handles.ImageData(i).Boundary.LensAngle = lensangle;
    handles.ImageData(i).Boundary.LensAngleImage = lensangleimage;
    handles.ImageData(i).Boundary.Parameters.A = MajorAxis;
    handles.ImageData(i).Boundary.Parameters.B = MinorAxis;
    handles.ImageData(i).Boundary.Parameters.Center = C;
    handles.ImageData(i).Boundary.Parameters.Phi = phi;
    handles.ImageData(i).Boundary.Parameters.Vertex = Vertex;
end
guidata(hObject, handles);


function AutoCornerFinder(hObject, handles, i)
[PointsFinal, CoordinatesFinal, NumberOfBlackSquares, FailSafeStruct] = DetectCorners(handles.ImageData(i).ImageGray,handles.ImageData(i).Boundary,...
    0, handles.ImageData(i).Info.IsArthroscopic,handles.ImageData(i).Info.GridSize);
handles.ImageData(i).PosImageAuto = [transpose(PointsFinal); ones(1,length(PointsFinal))];
handles.ImageData(i).PosPlaneAuto = [transpose(CoordinatesFinal); ones(1,length(PointsFinal))];
guidata(hObject,handles)

function FirstLinearCalib (hObject, handles, CALIBMETHOD, i)
handles.ImageData(i).InitCalib=SingleImgCalibration(handles.ImageData(i).PosPlaneAuto,handles.ImageData(i).PosImageAuto,CALIBMETHOD);
handles.ImageData(i).InitCalib.ReProjError=ReProjectionError(handles.ImageData(i).InitCalib,handles.ImageData(i).PosPlaneAuto,handles.ImageData(i).PosImageAuto);
guidata(hObject,handles);

function GetAdditionalPoints(hObject,handles,i)
ImgStruct=struct('Info',handles.ImageData(i).Info,'ImageGray',handles.ImageData(i).ImageGray,'Conic',handles.ImageData(i).Boundary);
[handles.ImageData(i).PosPlane, handles.ImageData(i).PosImage]=GetMorePoints(ImgStruct,handles.ImageData(i).InitCalib,handles.ImageData(i).PosPlaneAuto,handles.ImageData(i).PosImageAuto);
guidata(hObject,handles);

function SecondLinearCalib(hObject,handles, CALIBMETHOD, i)
handles.ImageData(i).FinalCalib=SingleImgCalibration(handles.ImageData(i).PosPlane,handles.ImageData(i).PosImage,CALIBMETHOD);
handles.ImageData(i).FinalCalib.ReProjError=ReProjectionError(handles.ImageData(i).FinalCalib,handles.ImageData(i).PosPlane,handles.ImageData(i).PosImage);
disp(sprintf('Final calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
    handles.ImageData(i).FinalCalib.qsi,handles.ImageData(i).FinalCalib.eta,handles.ImageData(i).FinalCalib.focal,handles.ImageData(i).FinalCalib.center(1),...
    handles.ImageData(i).FinalCalib.center(2), handles.ImageData(i).FinalCalib.skew,handles.ImageData(i).FinalCalib.aratio))
guidata(hObject,handles);

function StartByARTHROSYNC(hObject, eventdata, handles, directory, dirtosave ,gridsize)
disp('Application started by ARTHRO-SYNC')
%Set the function to call when we atempt to close the GUI
set(handles.figure1,'CloseRequestFcn',@closeGUI);
% set the grid size
set(handles.edit_gridsize,'string',gridsize)
% set calibration options
set(handles.checkbox_changeorigins,'Value',1);
% set(handles.hand_eye,'Value',1);
set(handles.refine,'Value',1);
% set the image list
dir_struct = dir(directory);
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
for i=1:length(sorted_names)
    [path,name,ext] = fileparts(sorted_names{i});
    if (strcmpi(ext,'.tiff'))
        if strcmpi(name(1:6),'Arthro')
            p = sprintf('%s%s%s',directory,name,ext);
            n = sprintf('%s%s',name,ext);
            valid = 1;
            for j = 1:length(handles.caliblistpath)
                if strcmpi(handles.caliblistpath(j),p)
                    valid = 0;
                end
            end
            if valid
                handles.caliblist(length(handles.caliblist)+1,1) = {n};
                handles.caliblistpath(length(handles.caliblistpath)+1,1) = {p};
            end
        end
    end
end
load_listbox_tocalibrate(handles.caliblist,handles);
handles.FROMARTHROSYNC=1;
handles.dirtosavecalib=dirtosave;
guidata(hObject, handles);
pushbutton_start_Callback(hObject, eventdata, handles);

function closeGUI(src,evnt)
%src is the handle of the object generating the callback (the source of the event)
%evnt is the The event data structure (can be empty for some callbacks)
exit

%% Creating and Deleting Functions
function dirlist_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function tocalibrate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function figure1_CreateFcn(hObject, eventdata, handles)
setappdata(hObject, 'StartPath', pwd);
addpath(pwd);

function figure1_DeleteFcn(hObject, eventdata, handles)
if isappdata(hObject, 'StartPath')
    rmpath(getappdata(hObject, 'StartPath'));
end

function radio_pointgrey_CreateFcn(hObject, eventdata, handles)

function radio_arthroimage_CreateFcn(hObject, eventdata, handles)

function edit_gridsize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% List Box
function dirlist_Callback(hObject, eventdata, handles)
get(handles.figure1,'SelectionType');
if strcmpi(get(handles.figure1,'SelectionType'),'open')
    ind = get(handles.dirlist,'Value');
    file_list = get(handles.dirlist,'String');
    filename = file_list{ind};
    if  handles.is_dir(handles.sorted_index(ind))
        cd (filename)
        load_listbox(pwd,handles)
    else
        [path,name,ext] = fileparts(filename);
        if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif') || strcmpi(ext,'.png') || strcmpi(ext,'.jpg') || strcmpi(ext,'.bmp'))
            p = sprintf('%s%s%s%s',pwd,filesep,name,ext);
            n = sprintf('%s%s',name,ext);
            valid = 1;
            for i = 1:length(handles.caliblistpath)
                if strcmpi(handles.caliblistpath(i),p)
                    valid = 0;
                end
            end
            if valid
                handles.caliblist(length(handles.caliblist)+1,1) = {n};
                handles.caliblistpath(length(handles.caliblistpath)+1,1) = {p};
            end
        else
            errordlg('Invalid Image File','File Type Error','modal')
        end
        load_listbox_tocalibrate(handles.caliblist,handles);
    end
end
if strcmpi(get(handles.figure1,'SelectionType'),'normal')
    ind = get(handles.dirlist,'Value');
    file_list = get(handles.dirlist,'String');
    filename = file_list{ind};
    [path,name,ext] = fileparts(filename);
    if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif') || strcmpi(ext,'.png') || strcmpi(ext,'.jpg') || strcmpi(ext,'.bmp'))
        preview = imread(filename);
        axes(handles.image_preview);
        image(preview);
        axis off
        drawnow
    end
end

function tocalibrate_Callback(hObject, eventdata, handles)
if handles.LISTMODE
    get(handles.figure1,'SelectionType');
    if strcmpi(get(handles.figure1,'SelectionType'),'normal')
        i = get(handles.tocalibrate,'Value');
        handles.CurrentInd = i;
        guidata(hObject, handles);
        DrawAll(handles,i);
        DrawTrans(hObject, handles,i);
        DisplayResults(handles,i,handles.showOPT);
        DisplayRepError(handles,handles.showOPT,handles.dispVALUES);
        BoldRepError(handles,handles.CurrentInd);
    end
else
    get(handles.figure1,'SelectionType');
    if strcmpi(get(handles.figure1,'SelectionType'),'open')
        ind = get(handles.tocalibrate,'Value');
        handles.caliblist(ind)=[];
        handles.caliblistpath(ind)=[];
        load_listbox_tocalibrate(handles.caliblist,handles);
    end
    if strcmpi(get(handles.figure1,'SelectionType'),'normal')
        ind = get(handles.tocalibrate,'Value');
        file_list = get(handles.tocalibrate,'String');
        filename = file_list{ind};
        [path,name,ext] = fileparts(filename);
        if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif') || strcmpi(ext,'.jpg') || strcmpi(ext,'.bmp'))
            preview = imread(handles.caliblistpath{ind});
            axes(handles.image_preview);
            image(preview);
            axis off
            drawnow
        end
    end
end
uicontrol(handles.tocalibrate);
guidata(hObject, handles);


function load_listbox(dir_path,handles)
cd (dir_path)
dir_struct = dir(dir_path);
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
handles.file_names = sorted_names;
handles.is_dir = [dir_struct.isdir];
handles.sorted_index = sorted_index;
set(handles.text_path, 'String',dir_path);
guidata(handles.figure1,handles)
set(handles.dirlist,'String',handles.file_names,'Value',1)


function load_listbox_tocalibrate(sorted_names,handles)
sorted_index_tocalibrate = [1:length(sorted_names)]';
handles.file_names_tocalibrate = sorted_names;
handles.sorted_index_tocalibrate = sorted_index_tocalibrate;
guidata(handles.figure1,handles)
set(handles.tocalibrate,'String',handles.file_names_tocalibrate,'Value',1)



function pushbutton_adddir_Callback(hObject, eventdata, handles)
get(handles.figure1,'SelectionType');
if strcmpi(get(handles.figure1,'SelectionType'),'normal')
    ind = get(handles.dirlist,'Value');
    file_list = get(handles.dirlist,'String');
    filename = file_list{ind};
    if  handles.is_dir(handles.sorted_index(ind))
        dir_struct = dir(filename);
        [sorted_names,sorted_index] = sortrows({dir_struct.name}');
        for i=1:length(sorted_names)
            [path,name,ext] = fileparts(sorted_names{i});
            if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif') || strcmpi(ext,'.jpg') || strcmpi(ext,'.bmp'))
                p = sprintf('%s%s%s%s%s%s',pwd,filesep,filename,filesep,name,ext);
                n = sprintf('%s%s',name,ext);
                valid = 1;
                for i = 1:length(handles.caliblistpath)
                    if strcmpi(handles.caliblistpath(i),p)
                        valid = 0;
                    end
                end
                if valid
                    handles.caliblist(length(handles.caliblist)+1,1) = {n};
                    handles.caliblistpath(length(handles.caliblistpath)+1,1) = {p};
                end
            end
        end
        load_listbox_tocalibrate(handles.caliblist,handles);
    end
end


function pushbutton_removeimage_Callback(hObject, eventdata, handles)
if strcmpi(get(handles.figure1,'SelectionType'),'normal')
    ind = get(handles.tocalibrate,'Value');
    handles.caliblist(ind)=[];
    handles.caliblistpath(ind)=[];
    load_listbox_tocalibrate(handles.caliblist,handles);
end
guidata(hObject, handles);


function pushbutton_clearlist_Callback(hObject, eventdata, handles)
if handles.LISTMODE==0
    handles.caliblist={};
    handles.caliblistpath={};
    load_listbox_tocalibrate(handles.caliblist,handles);
    guidata(hObject, handles);
else
    j=1;
    for i=1:length(handles.ImageData)
        if i~=handles.CurrentInd
            temp(j)=handles.ImageData(i);
            j=j+1;
        end
    end
    handles.ImageData=temp;
    tocalibrateFromMat(handles);
    SwitchMode(hObject, eventdata, handles);
    guidata(hObject, handles);
    tocalibrate_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
end

% Load the CalibData_temp.mat and switch the UI to work in  
function autoLoadMat(hObject, eventdata, handles)
handles.LISTMODE=1;
handles.ImageData = [];
ClearImages(handles,1,0);
guidata(hObject, handles);
load(sprintf('%sCalibData_temp.mat',handles.ARTHRODIR));
if (exist('ImageData','var'))
    handles.ImageData = ImageData;
    tocalibrateFromMat(handles);
    SwitchMode(hObject, eventdata, handles);
else
    errordlg('No ImageData structure found. Please check if you have opened the right .mat file','Bad Data File','modal')
end
guidata(hObject, handles);
tocalibrate_Callback(hObject, eventdata, handles)

function switch_to_Callback(hObject, eventdata, handles)
if handles.LISTMODE
    handles.LISTMODE=0;
    handles.ImageData = [];
    ClearImages(handles,1,0);
    SwitchMode(hObject, eventdata, handles);
    handles.caliblist={};
    handles.caliblistpath={};
    load_listbox_tocalibrate(handles.caliblist,handles);
else
    uiopen('MATLAB');
    if (exist('ImageData','var'))
        handles.ImageData = ImageData;
        tocalibrateFromMat(handles);
        handles.LISTMODE=1;
        if(isfield(handles.ImageData,'OptimCalib'))
            handles.REFINEMENT=1;
        end
        ClearImages(handles,1,0);
        SwitchMode(hObject, eventdata, handles);
        tocalibrate_Callback(hObject, eventdata, handles)
    end
end
guidata(hObject, handles);


function tocalibrateFromMat(handles)
list={};
for ind=1:length(handles.ImageData)
    list{ind} = sprintf('Image%.2d',ind);
end
load_listbox_tocalibrate(list, handles);


%% Options
function pushbutton_manual_Callback(hObject, eventdata, handles)
handles.ImageData = ManualPointsSelectionAutoCalibGUI(handles.ImageData);
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
guidata(hObject, handles);

function edit_gridsize_Callback(hObject, eventdata, handles)

function text_path_Callback(hObject, eventdata, handles)
user_entry = get(hObject,'string');
load_listbox(user_entry,handles);

function refine_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.REFINEMENT = 1;
else
    handles.REFINEMENT = 0;
end
guidata(hObject, handles);

function hand_eye_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.HANDEYE = 1;
else
    handles.HANDEYE = 0;
end
guidata(hObject, handles);

function savemenu_Callback(hObject, eventdata, handles)

function savedatamenu_Callback(hObject, eventdata, handles)
WriteMatResults(handles.ImageData,[]);

function checkbox_changeorigins_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.CHANGEORIGINS = 1;
else
    handles.CHANGEORIGINS = 0;
end
guidata(hObject, handles);

function pushbutton_addimage_Callback(hObject, eventdata, handles)
ind = get(handles.dirlist,'Value');
file_list = get(handles.dirlist,'String');
filename = file_list{ind};
if  handles.is_dir(handles.sorted_index(ind))
    cd (filename)
    load_listbox(pwd,handles)
else
    [path,name,ext,ver] = fileparts(filename);
    if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif'))
        p = sprintf('%s%s%s%s',pwd,filesep,name,ext);
        n = sprintf('%s%s',name,ext);
        valid = 1;
        for i = 1:length(handles.caliblistpath)
            if strcmpi(handles.caliblistpath(i),p)
                valid = 0;
            end
        end
        if valid
            handles.caliblist(length(handles.caliblist)+1,1) = {n};
            handles.caliblistpath(length(handles.caliblistpath)+1,1) = {p};
        end
    else
        errordlg(lasterr,'File Type Error','modal')
    end
    load_listbox_tocalibrate(handles.caliblist,handles);
end
guidata(hObject, handles);

function switch_coordinates_Callback(hObject, eventdata, handles)
if(handles.switchCOORDINATES)
    handles.switchCOORDINATES=0;
    set(handles.switch_coordinates,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchCOORDINATES=1;
    set(handles.switch_coordinates,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_handeyerefined_Callback(hObject, eventdata, handles)
if(handles.switchHANDEYEREFINED)
    handles.switchHANDEYEREFINED=0;
    set(handles.switch_handeyerefined,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchHANDEYEREFINED=1;
    set(handles.switch_handeyerefined,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_handeye_Callback(hObject, eventdata, handles)
if(handles.switchHANDEYE)
    handles.switchHANDEYE=0;
    set(handles.switch_handeye,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchHANDEYE=1;
    set(handles.switch_handeye,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_autocorners_Callback(hObject, eventdata, handles)
if(handles.switchPOSIMAGEAUTO)
    handles.switchPOSIMAGEAUTO=0;
    handles.switchPOSIMAGE=1;
    set(handles.switch_autocorners,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchPOSIMAGEAUTO=1;
    handles.switchPOSIMAGE=0;
    set(handles.switch_autocorners,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_boundary_Callback(hObject, eventdata, handles)
if(handles.switchBOUNDARY)
    handles.switchBOUNDARY=0;
    set(handles.switch_boundary,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchBOUNDARY=1;
    set(handles.switch_boundary,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_initcalib_Callback(hObject, eventdata, handles)
if(handles.switchINITCALIB)
    handles.switchINITCALIB=0;
    set(handles.switch_initcalib,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchINITCALIB=1;
    set(handles.switch_initcalib,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_finalcalib_Callback(hObject, eventdata, handles)
if(handles.switchFINALCALIB)
    handles.switchFINALCALIB=0;
    set(handles.switch_finalcalib,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchFINALCALIB=1;
    set(handles.switch_finalcalib,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_optimcalib_Callback(hObject, eventdata, handles)
if(handles.switchOPTIMCALIB)
    handles.switchOPTIMCALIB=0;
    set(handles.switch_optimcalib,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchOPTIMCALIB=1;
    set(handles.switch_optimcalib,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function switch_blamepoints_Callback(hObject, eventdata, handles)
if(handles.switchBLAMEPOINTS)
    handles.switchBLAMEPOINTS=0;
    set(handles.switch_blamepoints,'BackgroundColor',[0.702 0.702 0.702]);
else
    handles.switchBLAMEPOINTS=1;
    set(handles.switch_blamepoints,'BackgroundColor',[233 138 62]./255);
end
guidata(hObject, handles);
DrawAll(handles,handles.CurrentInd);

function checkbox7_Callback(hObject, eventdata, handles)

function groupbox_show_SelectionChangeFcn(hObject, eventdata, handles)
switch get(hObject,'Tag')   % Get Tag of selected object
    case 'radiobutton_showinit'
        handles.showOPT = 0;
    case 'radiobutton_showfinal'
        handles.showOPT = 1;
    case 'radiobutton_showoptim'
        handles.showOPT = 2;
    otherwise
        disp('UNKNOWN')
end
DisplayResults(handles,handles.CurrentInd,handles.showOPT);
guidata(hObject, handles);
DisplayRepError(handles,handles.showOPT,handles.dispVALUES);
BoldRepError(handles,handles.CurrentInd);
DrawTrans(hObject,handles,handles.CurrentInd)

function imagesource_SelectionChangeFcn(hObject, eventdata, handles)
switch get(hObject,'Tag')   % Get Tag of selected object
    case 'radio_arthroimage'
        handles.ISARTHROSCOPIC = 1;
    case 'radio_pointgrey'
        handles.ISARTHROSCOPIC = 0;
    otherwise
        disp('UNKNOWN')
end
guidata(hObject, handles);

function pushbutton_value_Callback(hObject, eventdata, handles)
if(~handles.dispVALUES)
    handles.dispVALUES=1;
    set(handles.pushbutton_value,'BackgroundColor',[233 138 62]./255);
    set(handles.pushbutton_bars,'BackgroundColor',[0.702 0.702 0.702]);
end
guidata(hObject, handles);
DisplayRepError(handles,handles.showOPT,handles.dispVALUES)

function pushbutton_bars_Callback(hObject, eventdata, handles)	
if(handles.dispVALUES)
    handles.dispVALUES=0;
    set(handles.pushbutton_bars,'BackgroundColor',[233 138 62]./255);
    set(handles.pushbutton_value,'BackgroundColor',[0.702 0.702 0.702]);
end
guidata(hObject, handles);
DisplayRepError(handles,handles.showOPT,handles.dispVALUES)


function calibverify_Callback(hObject, eventdata, handles)

function undistort_Callback(hObject, eventdata, handles)
CorrectImage('dir',handles.ARTHRODIR);


function homochecker_Callback(hObject, eventdata, handles)
Homography;

function edit_Callback(hObject, eventdata, handles)

function edit_options_Callback(hObject, eventdata, handles)
setappdata(0,'PROJECTPATH',handles.PROJECTPATH);
setappdata(0,'DEFAULTOPTIONSPATH',handles.defaultOptionsPath);
hopt=Options; %Call the eoptions GUI
waitfor(hopt); %Wait for the GUI to close

function loadOptions(hObject, handles)
% load the current options, or the default option from a file.
curroptpath=sprintf('%stemp%scurrentOptions.mat',handles.PROJECTPATH,filesep);
if(exist(curroptpath,'file'))
    fprintf('Loading current options: %s \n', curroptpath);
    temp=load(curroptpath);
else
    fprintf('Loading default options: %s \n', handles.defaultOptionsPath);
    if(exist(handles.defaultOptionsPath))
        temp=load(handles.defaultOptionsPath);
    else
        fprintf('No default configuration file found... Creating one. Check the configuration using the GUI.')
        optionsGUI.ISARTHROSCOPIC = 0;
        optionsGUI.REFINEMENT = 0;
        optionsGUI.CHANGEORIGINS = 0;
        optionsGUI.GRIDSIZE = 2;
        optionsGUI.DISCARDFAIL = 1;
        optionsGUI.ABORTONIMAGEFAILURE = 1;
        optionsGUI.OPENEDOPTIONS = 0;
        save(handles.defaultOptionsPath,'optionsGUI')
        temp=load(handles.defaultOptionsPath);
    end
end
if(~isfield(temp,'optionsGUI'))
    disp('Bad options file, aborting...');
    return;
end
try
    handles.ISARTHROSCOPIC = temp.optionsGUI.ISARTHROSCOPIC;
    handles.REFINEMENT = temp.optionsGUI.REFINEMENT;
    handles.CHANGEORIGINS = temp.optionsGUI.CHANGEORIGINS;
    handles.GRIDSIZE = temp.optionsGUI.GRIDSIZE;
    handles.DISCARDFAIL = temp.optionsGUI.DISCARDFAIL;
    handles.ABORTONIMAGEFAILURE = temp.optionsGUI.ABORTONIMAGEFAILURE;
catch
    disp('warning: something is wrong with the options file. try to configure again using the gui or remove the files manually.')
end
guidata(hObject, handles);


function updateOptions (hObject, handles)
handles.OPENEDOPTIONS=getappdata(0,'OPENEDOPTIONS');
handles.ISARTHROSCOPIC=getappdata(0,'ISARTHROSCOPIC');
handles.REFINEMENT=getappdata(0,'REFINEMENT');
handles.CHANGEORIGINS=getappdata(0,'CHANGEORIGINS');
handles.GRIDSIZE=getappdata(0,'GRIDSIZE');
handles.DISCARDFAIL=getappdata(0,'DISCARDFAIL');
handles.ABORTONIMAGEFAILURE=getappdata(0,'ABORTONIMAGEFAILURE');
guidata(hObject, handles);


function savetotxt_Callback(hObject, eventdata, handles)
if(~isempty(handles.ImageData))
    [name, directory] = uiputfile('*.txt','Save the calibration parameters to a text file','Calibration');
    if directory ~= 0
        handles.dirtosavecalib=sprintf('%s%s',directory,name);
        guidata(hObject, handles);
        WriteResults(4,handles);
    end
end


function refinement_Callback(hObject, eventdata, handles)


% Aplly a first order division model non-linear optimization to the calibration parameters using ALL the images at once.
function firstorderrefine_Callback(hObject, eventdata, handles)
change_state(handles,'Refinning Calibration Parameters')
disp('Refinning the calibration parameters')
handles.REFINEMENT=1;
handles.ImageData = RefineCalibrationAutoCalibGUI(handles.ImageData,1);
handles.showOPT=2;
DisplayResults(handles,handles.CurrentInd,2);
DisplayRepError(handles,2,handles.dispVALUES);
%Automatically save the data into a temp file
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
handles.LISTMODE=1;
handles.REFINEMENT=0;
change_state(handles,'Done')
guidata(hObject, handles);

% Aplly a second order division model non-linear optimization to the calibration parameters using ALL the images at once.
function secondorderrefine_Callback(hObject, eventdata, handles)
change_state(handles,'Refinning Calibration Parameters')
disp('Refinning the calibration parameters')
handles.REFINEMENT=1;
handles.ImageData = RefineCalibrationAutoCalibGUI(handles.ImageData,2);
DisplayResults(handles,1,2);
DisplayRepError(handles,2,handles.dispVALUES);
set(handles.radiobutton_showoptim,'Value',1);
%Automatically save the data into a temp file
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
handles.LISTMODE=1;
handles.REFINEMENT=0;
change_state(handles,'Done')
guidata(hObject, handles);

% Aplly a first order division model non-linear optimization to the calibration parameters to each individual image.
function firstorderrefine1by1_Callback(hObject, eventdata, handles)
change_state(handles,'Refinning Calibration Parameters')
disp('Refinning the calibration parameters')
handles.REFINEMENT=1;
handles.ImageData = RefineCalibration1by1AutoCalibGUI(handles.ImageData,1);
DisplayResults(handles,1,2);
DisplayRepError(handles,2,handles.dispVALUES);
set(handles.radiobutton_showoptim,'Value',1);
%Automatically save the data into a temp file
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
handles.LISTMODE=1;
handles.REFINEMENT=0;
change_state(handles,'Done')
guidata(hObject, handles);


% Aplly a second order division model non-linear optimization to the calibration parameters to each individual image.
function secondorderrefine1by1_Callback(hObject, eventdata, handles)
change_state(handles,'Refinning Calibration Parameters')
disp('Refinning the calibration parameters')
handles.REFINEMENT=1;
handles.ImageData = RefineCalibration1by1AutoCalibGUI(handles.ImageData,2);
DisplayResults(handles,1,2);
DisplayRepError(handles,2,handles.dispVALUES);
set(handles.radiobutton_showoptim,'Value',1);
%Automatically save the data into a temp file
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
handles.LISTMODE=1;
handles.REFINEMENT=0;
change_state(handles,'Done')
guidata(hObject, handles);


function tools_Callback(hObject, eventdata, handles)


function addcorners_Callback(hObject, eventdata, handles)
handles.ImageData = ManualPointsSelectionCornerAutoCalibGUI(handles.ImageData, handles);
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_resetview.
function pushbutton_resetview_Callback(hObject, eventdata, handles)
axes(handles.trans);
cla(handles.trans,'reset');
view(0,90);
DrawTrans(hObject, handles,handles.CurrentInd);


% --- Executes on button press in pushbutton_rotate.
function pushbutton_rotate_Callback(hObject, eventdata, handles)
if(~handles.rotate)
    handles.rotate=1;
    handles.zoom=0;
    set(handles.pushbutton_rotate,'BackgroundColor',[233 138 62]./255);
    set(handles.pushbutton_zoom,'BackgroundColor',[0.702 0.702 0.702]);
end
axes(handles.trans);
zoom off
rotate3d on
guidata(hObject, handles);


% --- Executes on button press in pushbutton_zoom.
function pushbutton_zoom_Callback(hObject, eventdata, handles)
if(handles.rotate)
    handles.rotate=0;
    handles.zoom=1;
    set(handles.pushbutton_rotate,'BackgroundColor',[0.702 0.702 0.702]);
    set(handles.pushbutton_zoom,'BackgroundColor',[233 138 62]./255);
end
rotate3d off
zoom on
guidata(hObject, handles);


function pushbutton_autotrans_Callback(hObject, eventdata, handles)
if(~handles.autotrans)
    handles.autotrans=1;
    set(handles.pushbutton_autotrans,'BackgroundColor',[233 138 62]./255);
else
    handles.autotrans=0;
    set(handles.pushbutton_autotrans,'BackgroundColor',[0.702 0.702 0.702]);
end
DrawTrans(hObject, handles,handles.CurrentInd);
guidata(hObject, handles);


function pushbutton_options_Callback(hObject, eventdata, handles)
setappdata(0,'PROJECTPATH',handles.PROJECTPATH);
setappdata(0,'DEFAULTOPTIONSPATH',handles.defaultOptionsPath);
hopt=Options; %Call the eoptions GUI
waitfor(hopt); %Wait for the GUI to close


% --------------------------------------------------------------------
function originselect_Callback(hObject, eventdata, handles)
handles.ImageData = DefineOriginsSingleMarkManualAutoCalibGUI(handles.ImageData);
WriteMatResults(handles.ImageData,handles.ARTHRODIR);
autoLoadMat(hObject, eventdata, handles);
guidata(hObject, handles);



function LoadData_Callback(hObject, eventdata, handles)
handles.LISTMODE=0;
handles.ImageData = [];
ClearImages(handles,1,0);
SwitchMode(hObject, eventdata, handles);
handles.caliblist={};
handles.caliblistpath={};
load_listbox_tocalibrate(handles.caliblist,handles);
uiopen('MATLAB');
if (exist('ImageData','var'))
    handles.ImageData = ImageData;
    tocalibrateFromMat(handles);
    handles.LISTMODE=1;
    if(isfield(handles.ImageData,'OptimCalib'))
        handles.REFINEMENT=1;
    end
    ClearImages(handles,1,0);
    SwitchMode(hObject, eventdata, handles);
    tocalibrate_Callback(hObject, eventdata, handles)
end
guidata(hObject, handles);


function bouguetvseasycamcalib_Callback(hObject, eventdata, handles)
if handles.ImageData(1).OptimCalib.focal >=0
    Bouguet_VS_EasyCamCalib(handles.ImageData);
else
    errordlg('The calibration is not optimized. You need to run the refinement tool before comparing results with Bouguet.',...
        'No OptimCalib','modal')
end

function state_CreateFcn(hObject, eventdata, handles)
