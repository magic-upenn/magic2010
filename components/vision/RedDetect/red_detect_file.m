function [omni_flat, front, omni_cands, front_cands, omni_stats, front_stats] = red_detect_file(ofile,ffile,shift)
%[circle,best_mask,bound] = find_center(img);
	total = tic; 
	if nargin < 3
		shift = [0,0]; 
	end 
	omni  = imread(ofile); 
	front = imread(ffile);
	omni = imresize(omni,[600,800]); 
	omni = rgb2ycbcr(omni); 
	front = rgb2ycbcr(front); 
	if shift
		front = circshift(front,shift); 
	end
	front = imresize(front,[240,320]); 
	circle = [500,850,601]/2; 

	
		omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
		if shift
			omni_flat = circshift(omni_flat,[0 shift(2)]);
		end
		[omni_stats] = find_red_candidates(omni_flat(:,:,3));
		omni_flat = ycbcr2rgb(omni_flat); 	
		omni_stats(:,2:end) = round(omni_stats(:,2:end)/2); 
		omni_flat = omni_flat(1:2:end,1:2:end,:); 	
		omni_cand1 = draw_cand_zoom(omni_stats,1,omni_flat);  
		omni_cand2 = draw_cand_zoom(omni_stats,2,omni_flat);  
		omni_cand3 = draw_cand_zoom(omni_stats,3,omni_flat);  
		omni_cands = {omni_cand1,omni_cand2,omni_cand3}; 
		omni_stats(:,2:end) = round(omni_stats(:,2:end)); 
		rgb_omni= omni_flat; 
		cands = omni_cands; 
		stats = omni_stats;  
		
		[front_stats] = find_red_candidates(front(:,:,3));
		front = ycbcr2rgb(front); 
		front_cand1 = draw_cand_zoom(front_stats,1,front);  
		front_cand2 = draw_cand_zoom(front_stats,2,front);  
		front_cand3 = draw_cand_zoom(front_stats,3,front);  
		front_cands = {front_cand1,front_cand2,front_cand3}; 
		front_stats(:,2:end) = round(front_stats(:,2:end));
		cands = front_cands; 
		stats = front_stats;  
