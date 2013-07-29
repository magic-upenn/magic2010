function varargout = CorrectImage(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CorrectImage_OpeningFcn, ...
                   'gui_OutputFcn',  @CorrectImage_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


function CorrectImage_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for CorrectImage
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% clc;
fff=which('CorrectImage');
[s d dd] = fileparts(fff);
ind = find(double(s)==double(filesep));
handles.PROJECTPATH = s(1:ind(end));
addpath(sprintf('%s%sInterfaces',handles.PROJECTPATH,filesep));
addpath(sprintf('%s%sInterfaces%sBinInterfaces',handles.PROJECTPATH,filesep,filesep));

handles.ISARTHROSCOPIC = 0;
handles.imagepath = {};     %Contains the full path of the image
handles.calibpath = {};     %Contains the full path of the calibration file
handles.l1dir={};
handles.l2dir={};
set(handles.x,'Visible','off');
set(handles.y,'Visible','off');
set(handles.text_width,'Visible','off');
set(handles.text_height,'Visible','off');

dummy1 = ones(300,450,3);
axes(handles.image_preview);
image(dummy1);
axis normal;
axis off

initial_dir = handles.PROJECTPATH;
if nargin > 4
    if strcmpi(varargin{1},'dir')
        if exist(varargin{2},'dir')
            initial_dir = varargin{2};
        else
            errordlg('Input argument must be a valid directory','Input Argument Error!')
            return
        end
    else
        errordlg('Unrecognized input argument','Input Argument Error!');
        return;
    end
end
h=load_listbox2(initial_dir,handles);
h1=load_listbox(initial_dir,h);
guidata(handles.figure1,h1);


function varargout = CorrectImage_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;


function pushbutton_start_Callback(hObject, eventdata, handles)
clc     
if isempty(handles.calibpath)
    errordlg('You must select a calibration file to proceed','Bad Input','modal')
    return 
end
load(handles.calibpath);
if (~exist('ImageData','var'))
    errordlg('The data file is invalid.')
    return
end
if ImageData(1).OptimCalib.focal==-1  %No optimcalibdata
    errordlg('The calibration file is not supported or does not contain optimal calibration data.','Bad Input','modal')
    return
end
if isempty(handles.imagepath)
    errordlg('You must select an image file to proceed','Bad Input','modal')
    return 
end
I=imread(handles.imagepath);

if ~handles.ISARTHROSCOPIC
    if(ImageData(1).Info.IsArthroscopic)
        FinalImage=RemoveImgDistDivInter(I,-1/(ImageData(1).OptimCalib.eta)^2,ImageData(1).OptimCalib.center','linear',0);
    else
        FinalImage=RemoveImgDistDivInter(I,-1/(ImageData(1).OptimCalib.eta)^2,ImageData(1).OptimCalib.center','linear',1);
    end
else
    if isnan(str2double(get(handles.x,'string'))) || isnan(str2double(get(handles.y,'string')))
        errordlg('You must enter a numeric value on desired undistorted size','Bad Input','modal')
        return
    end
    UNDx=str2double(get(handles.x,'string'));
    UNDy=str2double(get(handles.y,'string'));
    if(ImageData(1).Info.IsArthroscopic)
        FinalImage=RemoveImgDistEta(I,ImageData(1).OptimCalib,ImageData(1).Boundary,[UNDx UNDy]);
    else
        b.Points=[1 ImageData(1).Info.Resolution(1) 10;1 ImageData(1).Info.Resolution(2) 10;1 1 10]; %10 is a dummy value just to have equal dimensions in order to use the length function
        FinalImage=RemoveImgDistEta(I,ImageData(1).OptimCalib,b,[UNDx UNDy]);
    end
end



figure
imshow(I);
title('Distorted image')
figure
imshow(FinalImage)
title('Undistorted image')




function dirlist_Callback(hObject, eventdata, handles)
cd(handles.l1dir);
get(handles.figure1,'SelectionType');
if strcmpi(get(handles.figure1,'SelectionType'),'open')
    ind = get(handles.dirlist,'Value');
    file_list = get(handles.dirlist,'String');
    filename = file_list{ind};
    if  handles.is_dir(handles.sorted_index(ind))
        cd (filename)
        h=load_listbox(pwd,handles);
        guidata(handles.figure1,h);
    end
end
if strcmpi(get(handles.figure1,'SelectionType'),'normal')
    ind = get(handles.dirlist,'Value');
    file_list = get(handles.dirlist,'String');
    filename = file_list{ind};
    [path,name,ext] = fileparts(filename);
    if (strcmpi(ext,'.tiff') || strcmpi(ext,'.jpeg') || strcmpi(ext,'.tif') || strcmpi(ext,'.jpg') || strcmpi(ext,'.bmp') || strcmpi(ext,'.png'))
        preview = imread(filename);
        axes(handles.image_preview);
        image(preview);
        axis off
        drawnow
        p = sprintf('%s%s%s%s',pwd,filesep,name,ext);
        handles.imagepath=p;
    else
        handles.imagepath={};
    end
    guidata(handles.figure1,handles);
end


function caliblist_Callback(hObject, eventdata, handles)
cd(handles.l2dir);
get(handles.figure1,'SelectionType');
if strcmpi(get(handles.figure1,'SelectionType'),'open')
    ind = get(handles.caliblist,'Value');
    file_list = get(handles.caliblist,'String');
    filename = file_list{ind};
    if  handles.is_dir2(handles.sorted_index2(ind))
        cd (filename)
        h=load_listbox2(pwd,handles);
        guidata(handles.figure1,h);
    end
end
if strcmpi(get(handles.figure1,'SelectionType'),'normal')
    ind = get(handles.caliblist,'Value');
    file_list = get(handles.caliblist,'String');
    filename = file_list{ind};
    [path,name,ext] = fileparts(filename);
    if strcmpi(ext,'.mat')
        p = sprintf('%s%s%s%s',pwd,filesep,name,ext);
        handles.calibpath=p;
    else 
        handles.calibpath={};
    end
    guidata(handles.figure1,handles);
end


function handles=load_listbox(dir_path,handles)
cd (dir_path)
dir_struct = dir(dir_path);
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
handles.file_names = sorted_names;
handles.is_dir = [dir_struct.isdir];
handles.sorted_index = sorted_index;
handles.l1dir=dir_path;
% guidata(handles.figure1,handles)
set(handles.dirlist,'String',handles.file_names,'Value',1)

function handles=load_listbox2(dir_path,handles)
cd (dir_path)
dir_struct = dir(dir_path);
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
handles.file_names2 = sorted_names;
handles.is_dir2 = [dir_struct.isdir];
handles.sorted_index2 = sorted_index;
handles.l2dir=dir_path;
% guidata(handles.figure1,handles)
set(handles.caliblist,'String',handles.file_names2,'Value',1)

function dirlist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function text_path_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function caliblist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function x_Callback(hObject, eventdata, handles)

function x_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function y_Callback(hObject, eventdata, handles)

function y_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
switch get(hObject,'Tag')   % Get Tag of selected object
    case 'arthroscopic'
        handles.ISARTHROSCOPIC = 1;
        set(handles.x,'Visible','on');
        set(handles.y,'Visible','on');
        set(handles.text_width,'Visible','on');
        set(handles.text_height,'Visible','on');
    case 'pointgrey'
        handles.ISARTHROSCOPIC = 0;
        set(handles.x,'Visible','off');
        set(handles.y,'Visible','off');
        set(handles.text_width,'Visible','off');
        set(handles.text_height,'Visible','off');
    otherwise
        disp('UNKNOWN')
end
guidata(hObject, handles);



function optimalsize_Callback(hObject, eventdata, handles)
clc
if isempty(handles.calibpath)
    errordlg('You must select a calibration file to proceed','Bad Input','modal')
    return 
end
load(handles.calibpath);
if (~exist('ImageData','var'))
    errordlg('The data file is invalid.')
    return
end
if ImageData(1).OptimCalib.focal==-1  %No optimcalibdata
    errordlg('The calibration file is not supported or does not contain optimal calibration data.','Bad Input','modal')
    return
end

%Compute optimal undistorted size 
xd = ImageData(1).Info.Resolution(1);
yd = ImageData(1).Info.Resolution(2);
rmm = inv(ImageData(1).OptimCalib.K)*[xd;yd;1];
cx = ImageData(1).OptimCalib.center(1);
cy = ImageData(1).OptimCalib.center(1);
cmm = inv(ImageData(1).OptimCalib.K)*[cx;cy;1];
rdmm = sqrt((rmm(1)-cmm(1))^2+(rmm(2)-cmm(1))^2);
rumm = rdmm/(1+ImageData(1).OptimCalib.qsi*rdmm);
ru = ImageData(1).OptimCalib.K*[sqrt(rumm^2/2);sqrt(rumm^2/2);1];
fprintf('Original image size: %g x %g\n',yd,xd)
fprintf('Optimal undistorted size: %g x %g\n',ru(1),ru(2))

%THIS MIGHT BE A MORE CORRECT CODE, CHECKOUT
% load ../temp/CalibData_EasyCamCalibRefined_1by1.mat
% 
% fprintf('Image Size: %dx%d\n', ImageData(1).Info.Resolution(2),ImageData(1).Info.Resolution(1))
% 
% %From the calibration
% qsi = ImageData(1).OptimCalib.qsi;
% K = ImageData(1).OptimCalib.K;
% 
% %Input points
% p=ImageData(1).Boundary.Points(1:2,:);
% [dist ind]=max(sqrt((p(1,:)-ImageData(1).OptimCalib.center(1)).^2 + (p(2,:)-ImageData(1).OptimCalib.center(2)).^2));
% xd=p(1,ind);
% yd=p(2,ind);
% 
% fprintf('Boundary point further away from the principal point: [%f %f] \n',xd,yd)
% 
% %Compute the undistorted radius
% rd=sqrt(dot([xd;yd],[xd;yd]));
% Pdmm=inv(K)*[xd;yd;1];
% Pumm=[Pdmm(1:2)./(1+qsi*dot(Pdmm(1:2),Pdmm(1:2))); 1];
% Pu=K*[Pumm];
% ru=sqrt(dot(Pu(1:2),Pu(1:2)));
% 
% 
% fprintf('Distorted radius: %f \n',rd)
% fprintf('Undistorted radius: %f \n',ru)

set(handles.x,'string',num2str(round(ru(1))));
set(handles.y,'string',num2str(round(ru(2))));
