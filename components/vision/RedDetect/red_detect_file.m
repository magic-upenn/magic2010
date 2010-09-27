function [omni_sm, front_sm, omni_cands, front_cands, omni_stats, front_stats] = red_detect_file(ofile,ffile)
%[circle,best_mask,bound] = find_center(img); 
	omni  = imread(ofile); 
	front = imread(ffile);
	front = imresize(front,.5); 
	circle = [500,850,601]; 
	%circle = [600,800,650]/2; 
	omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
	[red,omni_stats] = find_red_candidates(omni_flat); 
	[red,front_stats] = find_red_candidates(front);

	omni_cand1 = draw_cand_zoom(omni_stats,1,omni_flat);  
	front_cand1 = draw_cand_zoom(front_stats,1,front);  
	omni_cand2 = draw_cand_zoom(omni_stats,2,omni_flat);  
	front_cand2 = draw_cand_zoom(front_stats,2,front);  
	omni_cand3 = draw_cand_zoom(omni_stats,3,omni_flat);  
	front_cand3 = draw_cand_zoom(front_stats,3,front);  
	omni_cands = {omni_cand1,omni_cand2,omni_cand3}; 
	front_cands = {front_cand1,front_cand2,front_cand3}; 

	front_sm = imresize(front,[240,320]);
	omni_sm  = imresize(omni_flat,[155,775]);
	omni_scale = size(omni_sm,1)/size(omni_flat,1);   
	front_scale = size(front_sm,1)/size(front,1);   
	omni_stats(:,2:end) = round(omni_stats(:,2:end) * omni_scale); 
	front_stats(:,2:end) = round(front_stats(:,2:end) * front_scale);
