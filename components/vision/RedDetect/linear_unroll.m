function urimg = linear_unroll(img,cx,cy,rmax)
persistent width height BAD IND cxo cyo rmaxo 
if isempty(width)
	width = 0;
	height = 0;
	cxo = 0; 
	cyo = 0; 
	rmaxo = 0; 
end
 
%uh = 125
%uw = 1200
%rmin = 230
if any([width height cxo cyo rmaxo] ~= [size(img,2) size(img,1) cx cy rmax]); 
	cxo = cx; 
	cyo = cy;
	rmaxo = rmax;  
	width = size(img,2); 
	height = size(img,1);  
	uh = 200;
	uw = 1000;
	rmin = rmax*.40; 
	rmax = rmax*.90;;
	rrange = rmax - rmin; 
	[I,J] = meshgrid(1:uw,1:uh);
	PI = I * (2*pi/uw) - pi/2; 
	Uy = sin(PI); 
	Ux = cos(PI);
	Jscaled = J * (rrange/uh) + rmin;  
	RX = Ux .* Jscaled; 
	RY = Uy .* Jscaled;  
	RX = RX + cx;
	RY = RY + cy;
	BAD = (RX < 1) + (RX > width) + (RY < 1) + (RY > height);  
	BAD = BAD > 0; 
	RX(RX < 1) = 1;   
	RY(RY < 1) = 1;   
	RX(RX > width) = 1;    
	RY(RY > height) = 1;
	RY = round(RY); 
	RX = round(RX); 
	IND = sub2ind([height,width],RY,RX);
	IND(BAD) = 1; 
end

R = img(:,:,1);
G = img(:,:,2);   
B = img(:,:,3);
R(1) = 0;    
G(1) = 0;    
B(1) = 0;    
urimg = R(IND);
urimg(:,:,2) = G(IND);; 
urimg(:,:,3) = B(IND);; 
urimg = imrotate(urimg,180);
