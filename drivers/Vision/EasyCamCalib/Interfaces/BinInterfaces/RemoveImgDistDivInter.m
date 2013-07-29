% Corrects radial distortion assuming the division model of first order
% 
% FinalImage=RemoveImgDistDivInter(InitialImage,qsi,Center,method,real_data)
%
% qsi - is the distortion parameter (always negative)
% Center - Distortion center (if [] then it assume the image center)
% method - type of interpolation 'linear','cubic', etc (interp2)
% real_data - put 1 if the distorion has been added artificially and 0
% otherwise

function FinalImage=RemoveImgDistDivInter(InitialImage,qsi,Center,method,real_data)


[m,n,k]=size(InitialImage);
if isempty(Center)
 Center=[n/2;m/2];
end;
%Compute New Image Size
if real_data
 top_left=[1;1]-Center;
 top_left=top_left*((1+qsi*transpose(top_left)*top_left)^-1);
 top_right=[n;1]-Center;
 top_right=top_right*((1+qsi*transpose(top_right)*top_right)^-1);
 bottom_left=[1;m]-Center;
 bottom_left=bottom_left*((1+qsi*transpose(bottom_left)*bottom_left)^-1);
 bottom_right=[n;m]-Center;
 bottom_right=bottom_right*((1+qsi*transpose(bottom_right)*bottom_right)^-1);
 SizeX=max(ceil(sqrt((top_left(1)-top_right(1))^2+(top_left(2)-top_right(2))^2)),ceil(sqrt((bottom_left(1)-bottom_right(1))^2+(bottom_left(2)-bottom_right(2))^2)));
 SizeY=max(ceil(sqrt((top_left(1)-bottom_left(1))^2+(top_left(2)-bottom_left(2))^2)),ceil(sqrt((top_right(1)-bottom_right(1))^2+(top_right(2)-bottom_right(2))^2)));
else
 left_side=[1;Center(2)]-Center;
 right_side=[n;Center(2)]-Center;
 top_side=[Center(1);1]-Center;
 down_side=[Center(1);m]-Center;
 left_side=left_side*(1+qsi*transpose(left_side)*left_side)^-1;
 right_side=right_side*(1+qsi*transpose(right_side)*right_side)^-1;
 top_side=top_side*(1+qsi*transpose(top_side)*top_side)^-1;
 down_side=down_side*(1+qsi*transpose(down_side)*down_side)^-1;
 SizeX=ceil(sqrt((left_side(1)-right_side(1))^2+(left_side(2)-right_side(2))^2));
 SizeY=ceil(sqrt((top_side(1)-down_side(1))^2+(top_side(2)-down_side(2))^2));
end;
    SizeX
    SizeY
%Compute New Image Parameters
NewCenter=[SizeX/2;SizeY/2]
[X,Y]=meshgrid(1:SizeX,1:SizeY);
X=X-NewCenter(1);
Y=Y-NewCenter(2);
Z=ones(size(X));
R=sqrt(X.^2+Y.^2);
newZ=Z+(Z.^2-4*qsi*R.^2).^(1/2); newX=2*X./newZ; newY=2*Y./newZ;
%Render New Image
[X,Y]=meshgrid(1:n,1:m);X=X-Center(1);Y=Y-Center(2);
FinalImage=zeros(SizeY,SizeX,k);
if k==1
 FinalImage=interp2(X,Y,double(InitialImage),newX,newY);
else
 for i=1:1:k
  FinalImage(:,:,i)=interp2(X,Y,double(InitialImage(:,:,i)),newX,newY,method);
 end;
end;
for i=1:1:SizeY
 for j=1:1:SizeX
  for l=1:1:k
   if isnan(FinalImage(i,j,l));
    FinalImage(i,j,l)=0;
   end;
  end;
 end;
end;
FinalImage=uint8(FinalImage);

fprintf('Original Image Size is %d x %d \n',n,m);
fprintf('Final Image Size is %d x %d \n',SizeX,SizeY);
fprintf('Qsi value is %8f \n',qsi);
