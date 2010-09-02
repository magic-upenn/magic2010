function d = estimate_circle(img)
	b = [400;300;120]; 
	S = sum(img,3); 
	d = 1
	Cb = circle(b(1),b(2),b(3),size(img));
	Mb = mean(S(Cb)); 
	for i = 1:40
		Cb = circle(b(1),b(2),b(3),size(img));
		Nb = numel(find(Cb)); 
		Sb = Mb * Nb;    
		[size(S),size(Cb)] 
		imagesc(double(S).*Cb)
		pause(.1)
		M = [];
		B = []; 
		for x = [b(1)-d,b(1),b(1)+d]
			for y = [b(2)-d,b(2),b(2)+d]
				r = b(3);
				C = circle(x,y,r,size(img));
				Cd = (C-Cb);
				Cp = (Cd > 0);  
				Cn = (Cd < 0);
				Nt = Nb - numel(find(Cn)) + numel(find(Cp));
				St = Sb - sum(S(Cn)) + sum(S(Cp));
				%Mt = mean(S(C)); 
				Mt = St/Nt
				%[Mt,St/Nt]
				M = [M,Mt] ;
				B = [B,[x;y;r]]; 
			end
		end
		[Mb,i] = min(M);
		b = B(:,i)
		i
	end
	
	
