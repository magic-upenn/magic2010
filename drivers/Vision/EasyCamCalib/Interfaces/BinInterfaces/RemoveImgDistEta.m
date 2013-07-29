% Corrects radial distortion assuming the division model of first order using eta
function FinalImage=RemoveImgDistEta(InitialImage,CalibStruct, Boundary, outsize)

%Project the boundary and Undistort
Bmm=CalibStruct.Keta\Boundary.Points;
Bu=[Bmm(1,:)./(ones(1,length(Bmm))-(Bmm(1,:).^2+Bmm(2,:).^2)); Bmm(2,:)./(ones(1,length(Bmm))-(Bmm(1,:).^2+Bmm(2,:).^2))]; 
%Compute Ks matrix based on the undistorted contour
l=min(Bu(1,:));
r=max(Bu(1,:));
d=min(Bu(2,:));
u=max(Bu(2,:));
fx=1.1*((r-l)/outsize(1));
fy=1.1*((u-d)/outsize(2));
cx=l+(r-l)/2;
cy=d+(u-d)/2;
f=max([fx fy]);
cxs = -f*(0.5*outsize(1))+cx;
cys = -f*(0.5*outsize(2))+cy;
Ks=[f 0 cxs;0 f cys;0 0 1];

%Correct the image
[mi ni k]=size(InitialImage);
m=outsize(1);
n=outsize(2);  
[X Y]=meshgrid(1:m,1:n);                                                            
X=reshape(X,1,n*m);
Y=reshape(Y,1,n*m);
Pmm=Ks*[X;Y;ones(1,n*m)];                                                           %Bring to mm an scale
Phd=[2*Pmm(1,:);2*Pmm(2,:);Pmm(3,:)+sqrt(Pmm(3,:).^2+4*(Pmm(1,:).^2+Pmm(2,:).^2))]; %Distortion function (with z=1)
Phdn=Phd(1:3,:)./(ones(3,1)*Phd(3,:));                                              %Normalize
Pd=CalibStruct.Keta*Phdn;                                                           %Bring back to pixels
X1=reshape(Pd(1,:),n,m);                                                            
Y1=reshape(Pd(2,:),n,m);
[Xi Yi]=meshgrid(1:ni,1:mi);
for i=1:1:k
    FinalImage(:,:,i)=interp2(Xi,Yi,double(InitialImage(:,:,i)),X1,Y1);
end
FinalImage=uint8(FinalImage);