function varargout = Homography(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Homography_OpeningFcn, ...
                   'gui_OutputFcn',  @Homography_OutputFcn, ...
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


function Homography_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for Homography
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

dummy1 = ones(300,450,3);
axes(handles.p1);
image(dummy1);
axis normal;
axis off
axes(handles.p2);
image(dummy1);
axis normal;
axis off

fff=which('Homography');
[s d dd] = fileparts(fff);
ind = find(double(s)==double(filesep));
handles.PROJECTPATH = s(1:ind(end));
addpath(sprintf('%s%sInterfaces',handles.PROJECTPATH,filesep));
addpath(sprintf('%s%sInterfaces%sBinInterfaces',handles.PROJECTPATH,filesep,filesep));
cd(handles.PROJECTPATH);

guidata(hObject, handles);

function varargout = Homography_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;


function l1_Callback(hObject, eventdata, handles)
get(handles.figure1,'SelectionType');
if strcmp(get(handles.figure1,'SelectionType'),'normal')
    i = get(handles.l1,'Value');
    handles.CurrentInd1 = i;
    axes(handles.p1);
    if isfield(handles,'ImageData')
        image(handles.ImageData(i).ImageRGB);
    end
    axis off
    drawnow
    guidata(hObject, handles);
end


function l2_Callback(hObject, eventdata, handles)
get(handles.figure1,'SelectionType'); 
if strcmp(get(handles.figure1,'SelectionType'),'normal')
    i = get(handles.l2,'Value');
    handles.CurrentInd2 = i;
    axes(handles.p2);
    if isfield(handles,'ImageData')
        image(handles.ImageData(i).ImageRGB);
    end
    axis off
    drawnow
    guidata(hObject, handles);
end

function l1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function l2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function start_Callback(hObject, eventdata, handles)
USEHANDEYE = 0;
COMPUTEHOMOONLY = 0;
USEETA = 1;

data1 = handles.ImageData(handles.CurrentInd1);
data2 = handles.ImageData(handles.CurrentInd2);

%Images
I1 = data1.ImageGray;
I2 = data2.ImageGray;

if USEHANDEYE
    %OptoTracker Motions
    M1 = data1.Hand2Opto;
    M2 = data2.Hand2Opto;
    %HandEye
    HE = data1.Eye2Hand;
    %Motion between views 1 and 2 (the View2 points are referenced in the View1 frame)
    Tm = inv(HE)*inv(M1)*M2*HE
    %Extrinsics
    Plane2Eye = inv(HE) * inv(M2) * data2.Plane2Opto;
else
    E1 = data1.OptimCalib.T;
    E2 = data2.OptimCalib.T;
    Tm = E1*inv(E2);
    Plane2Eye = E2;
end
 
N = Plane2Eye(1:3,3);
d = Plane2Eye(1:3,4)'*N;

%Homography
H = (Tm(1:3,1:3) + d^-1*Tm(1:3,4)*N');
% H = [E1(1:3,1:2) E1(1:3,4)]*inv([E2(1:3,1:2) E2(1:3,4)]);

if COMPUTEHOMOONLY
   H
   return
end

[m n] = size(I1);

if USEETA
    %Intrinsics
    K = [data1.OptimCalib.aratio*data1.OptimCalib.eta data1.OptimCalib.skew*data1.OptimCalib.eta data1.OptimCalib.center(1);...
        0 data1.OptimCalib.aratio^-1*data1.OptimCalib.eta data1.OptimCalib.center(2);...
        0 0 1];
    [Xi Yi]=meshgrid(1:n,1:m);
    X=reshape(Xi,1,n*m);
    Y=reshape(Yi,1,n*m);
    Pmm=K\[X;Y;ones(1,n*m)];                                                %Bring to mm
    Fd=[Pmm(1,:); Pmm(2,:); ones(1,n*m)-(Pmm(1,:).^2+Pmm(2,:).^2)];         %Undistortion function (with z=1)
    Fdn=Fd(1:2,:)./(ones(2,1)*(Fd(3,:).*sqrt(-data2.OptimCalib.qsi)));      %Normalize and aplly scale factor
    Fdn=[Fdn;ones(1,length(Fdn))];
    Ph=(H*Fdn);                                                             %Apply homography
    Phn=Ph(1:2,:)./(ones(2,1)*(Ph(3,:).*sqrt(-data2.OptimCalib.qsi)^-1));   %Apply scale factor
    Phd=[2*Phn(1,:);2*Phn(2,:);1+sqrt(1+4*(Phn(1,:).^2+Phn(2,:).^2))];      %Distortion function (with z=1)
    Phdn=Phd(1:3,:)./(ones(3,1)*Phd(3,:));                                  %Normalize
    Pd=K*Phdn;                                                              %Bring back to pixels
    % ind=InsideConic(data1.Boundary.Omega,Pd,1);
    X1=reshape(Pd(1,:),m,n);
    Y1=reshape(Pd(2,:),m,n);
    I=interp2(Xi,Yi,double(I1),X1,Y1);
else
    %Intrinsics
    K = [data1.OptimCalib.aratio*data1.OptimCalib.focal data1.OptimCalib.skew*data1.OptimCalib.focal data1.OptimCalib.center(1);...
        0 data1.OptimCalib.aratio^-1*data1.OptimCalib.focal data1.OptimCalib.center(2);...
        0 0 1];
    qsi=data2.OptimCalib.qsi/(data2.OptimCalib.focal^2);
    [Xi Yi]=meshgrid(1:n,1:m);
    X=reshape(Xi,1,n*m);
    Y=reshape(Yi,1,n*m);
    Pmm=K\[X;Y;ones(1,n*m)];                                                                %Bring to mm
    Fd=[Pmm(1,:); Pmm(2,:); ones(1,n*m)+qsi*(Pmm(1,:).^2+Pmm(2,:).^2)];                     %Undistortion function (with z=1)
    Fdn=Fd(1:3,:)./(ones(3,1)*Fd(3,:));                                                     %Normalize
    Ph=(H*Fdn);                                                                             %Apply homography
    Phd=[2*Ph(1,:);2*Ph(2,:);Ph(3,:)+sqrt(Ph(3,:).^2-4*qsi*(Ph(1,:).^2+Ph(2,:).^2))];       %Distortion function
    Phdn=Phd(1:3,:)./(ones(3,1)*Phd(3,:));                                                  %Normalize
    Pd=K*Phdn;                                                                              %Bring back to pixels
    % ind=InsideConic(data1.Boundary.Omega,Pd,1);
    X1=reshape(Pd(1,:),m,n);
    Y1=reshape(Pd(2,:),m,n);
    I=interp2(Xi,Yi,double(I1),X1,Y1);
end

figure
imshow(I1)
title('Image 1')
figure
% subplot(2,2,1)
imshow(I2)
axis auto
title('Image 2')
figure
% subplot(2,2,2)
imshow(uint8(I))
axis auto
title('Homography (New image 2 generated from image 1)')
figure
% subplot(2,2,[3 4])
imshow(uint8(abs(double(I2)-I)))
axis auto
title('Difference')


function load_Callback(hObject, eventdata, handles)
uiopen('MATLAB');
if (exist('ImageData','var'))
    handles.ImageData = ImageData;
    tocalibrateFromMat(handles);
    l1_Callback(hObject, eventdata, handles)
    l2_Callback(hObject, eventdata, handles)
else
    errordlg('Invalid .mat file','Bad Input','modal')
end

    
function tocalibrateFromMat(handles)
list={};
for ind=1:length(handles.ImageData)
    list{ind} = sprintf('Image%.2d',ind);
end
load_listbox1(list, handles);
load_listbox2(list, handles);


function load_listbox1(sorted_names,handles)
sorted_index_tocalibrate = [1:length(sorted_names)]';
handles.file_names1 = sorted_names;
handles.sorted_index1 = sorted_index_tocalibrate;
guidata(handles.figure1,handles)
set(handles.l1,'String',handles.file_names1,'Value',1)


function load_listbox2(sorted_names,handles)
sorted_index_tocalibrate = [1:length(sorted_names)]';
handles.file_names2 = sorted_names;
handles.sorted_index2 = sorted_index_tocalibrate;
guidata(handles.figure1,handles)
set(handles.l2,'String',handles.file_names2,'Value',1)