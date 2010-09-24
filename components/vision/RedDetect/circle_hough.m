function Best = circle_hough(search,r_min,r_max)
if ~exist('r_min')
	r_min = 15;
end
if ~exist('r_max')
	r_max = 30;
end

skip_r = 2;
skip_p = 25; 

Rstats = []; 
[I,J,V] = find(search);
for r = r_min:skip_r:r_max 
	C = circle_outline(r,size(search),[r,r]);
	num_c = numel(find(C));
	num_s =  numel(find(search));
	Cxy = [I,J];
	H = zeros(size(search,1),size(search,2));
	skip_p = round(num_s/num_c) * 3;  
	for i = 1:skip_p:numel(I)
		cxy = Cxy(i,:);
		Cs = circshift(C,round(cxy-[r,r]));
		H = H + Cs;  
	end
	[Vmax,Imax] = max(H(:));
	Rstats = [Rstats;[r,Vmax,Imax]];  
%	subplot(1,2,1);  
%	[ib,jb] = ind2sub(size(search), Imax); 
%	best_mask_s = circle(r,size(search),[ib,jb]);  
%	imagesc(H)
%	subplot(1,2,2);  
%	imagesc(best_mask_s + search); 
%	pause(1)
%	[r,Vmax,Imax]
end
Rstats = sortrows(Rstats,2);
Best = Rstats(end,:);
[i,j] = ind2sub(size(search), Best(3)); 
Best = [i,j,Best(1)];  
