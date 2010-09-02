function b = estimate_circle_fast(img,b)
	%b = [400;300;120]; 
	S = sum(img,3); 
	d = 1;
	Cb = circle(b(1),b(2),b(3),size(img));
	Mb = mean(S(Cb));
	bd = [0;0;0];  
	for iter = 1:40
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
		[Mb,i] = min(M);
		bd = b - B(:,i);
		b = B(:,i);
		if all(bd == 0)
			break; 
		end
		iter
	end
	
	
