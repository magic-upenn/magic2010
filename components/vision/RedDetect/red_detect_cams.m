function [omni_sm, front_sm, omni_stats, front_stats] = red_detect_cams()
	omni  = get_image(0,3); 
	front = get_image(1,3);
	circle = [600,800,650]/2; 
	omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
	[red,omni_stats] = find_red_candidates(omni_flat); 
	[red,front_stats] = find_red_candidates(front);
	front_sm = imresize(front,[240,320]);
	omni_sm  = imresize(omni_flat,[155,775]);
	omni_scale = size(omni_sm,1)/size(omni_flat,1);   
	front_scale = size(front_sm,1)/size(front,1);   
	omni_stats(:,2:end) = round(omni_stats(:,2:end) * omni_scale); 
	front_stats(:,2:end) = round(front_stats(:,2:end) * front_scale); 
	%omni_cand  = draw_cand_zoom(omni_stats,1,flat_sm,[0,255,0])); daspect([1 1 1]); 
	%front_cand = draw_cand_zoom(front_stats,1,front_sm,[0,255,0])); daspect([1 1 1]); 
	%omni_sm  = draw_cands(omni_stats,flat_sm)); daspect([1 1 1]);   
	%front_sm = draw_cands(front_stats,front_sm)); daspect([1 1 1]);
	
 
