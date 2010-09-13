function b = estimate_circle_fast(img,b)
	%b = [400;300;120]; 
	S = sum(img,3); 
	d = 1;
	l = 2;		
	%Cb = fspecial('gaussian',S(1:2),10);
	%Cb = Cb / Cb(100,100); 
	%Cb = min(Cb,ones(size(Cb)));
	Cb = sparse(circle(b(1),b(2),b(3),size(img)));
	Cb = (Cb == 1);
	%Cb = sparse(conv2(full(double(Cb)),ones(20)./20^2,'same'));
	Mb = mean(S(Cb > 0));
	bd = [0;0;0];  
	for iter = 1:50
		Cb = circshift(Cb,-[bd(2),bd(1)]);
		%Cb = circle(b(1),b(2),b(3),size(img));
		Nb = numel(find(Cb)); 
		Sb = Mb * Nb;    
		subplot(1,2,2)
		imagesc(double(S).*Cb)
		daspect([1 1 1]);
		axis off
		pause(.1)
		M = [];
		B = []; 
		for xd = [-d,0,d]
			for yd = [-d,0,d]
				x = b(1) + xd; 
				y = b(2) + yd; 
				r = b(3);
				C = circshift(Cb,[yd,xd]);
				Cd = (C-Cb);
				Cp = (Cd > 0);  
				Cn = (Cd < 0);
				Nt = Nb - numel(find(Cn)) + numel(find(Cp));
				St = Sb - sum(S(Cn)) + sum(S(Cp));
				%Mt = mean(S(C)); 
				Mt = St/Nt;
				%[Mt,St/Nt]
				M = [M,Mt] ;
				B = [B,[x;y;r]]; 
			end
		end
		Mbo = Mb; 
		[Mb,i] = min(M);
		bd = floor((Mbo-Mb)*l) * (b - B(:,i));
		b = b - bd;
		(Mbo-Mb)*l
		bd
		if all(bd == 0)
			break; 
		end
		iter
	end
	
	
