function [rgb_image, cands, stats] = red_detect_cams(cam)
	if strcmp(cam,'omni'); 
		omni  = get_image(0,1,'yuv'); 
		circle = [600,800,650]/2;
		omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
		[omni_stats] = find_red_candidates(omni_flat(:,:,3));
		omni_flat = ycbcr2rgb(omni_flat); 	
    omni_stats = omni_stats/2; 
    omni_flat = omni_flat(1:2:end,1:2:end,:); 	
    omni_cand1 = draw_cand_zoom(omni_stats,1,omni_flat);  
		omni_cand2 = draw_cand_zoom(omni_stats,2,omni_flat);  
		omni_cand3 = draw_cand_zoom(omni_stats,3,omni_flat);  
		omni_cands = {omni_cand1,omni_cand2,omni_cand3}; 
		omni_stats(:,2:end) = round(omni_stats(:,2:end)); 
		rgb_image = omni_flat; 
		cands = omni_cands; 
		stats = omni_stats;  
	end
	if strcmp(cam,'front'); 
		front = get_image(1,3,'yuv');
		front = imrotate(front,180); 
		[front_stats] = find_red_candidates(front(:,:,3));
		front = ycbcr2rgb(front); 
		front_cand1 = draw_cand_zoom(front_stats,1,front);  
		front_cand2 = draw_cand_zoom(front_stats,2,front);  
		front_cand3 = draw_cand_zoom(front_stats,3,front);  
		front_cands = {front_cand1,front_cand2,front_cand3}; 
		front_stats(:,2:end) = round(front_stats(:,2:end));
		rgb_image = front; 
		cands = front_cands; 
		stats = front_stats;  
	end
