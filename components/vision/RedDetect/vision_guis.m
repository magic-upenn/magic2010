%function vision_guis()

global FRONT
global OMNI
global FRONT_HANDLES;

%Draw inital front data
%if 0

all_stats = []; 
for i = 1:9
	fname = sprintf('front%d',i)
	all_stats = [all_stats; [ones(size(FRONT(i).stats,1),1),FRONT(i).stats]];
	FRONT(i).stats = flipud(sortrows(FRONT(i).stats,2));  
	draw_cands_on_image(FRONT_HANDLES.(fname),FRONT(i).stats,FRONT(i).img); 
	if i == 9
		break
	end
	cname = sprintf('cand%d',i)
	draw_cand_on_axes(FRONT_HANDLES.(cname),FRONT(i).stats,i,FRONT(i).img); 
end

%axes(FRONT_HANDLES.flat_focus);
%imagesc(OMNI(1).img) 
%axes(FRONT_HANDLES.front_focus); 
%imagesc(FRONT(1).img) 
%end
%for i =1:100000
%	%im = get_image();
%	im = uvcCam('read'); 
%	im = yuyv2rgb(im);
%	im = imresize(im,2,'nearest'); 
%	axes(FRONT_HANDLES.front_focus); 
%	imagesc(im); 
%	[red, stats] = find_red_candidates(im);
%	draw_cands_on_image(FRONT_HANDLES.front1,stats,im); 
%	draw_cand_on_axes(FRONT_HANDLES.cand1,stats,1,im);  	 
%	pause(1); 
%end

