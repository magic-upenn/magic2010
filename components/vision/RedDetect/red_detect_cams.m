function [rgb_image,stats] = red_detect_cams(cam)
	persistent circle
	if isempty(circle)
		try
			load omnical
			circle = [cy,cx,650/2];
		catch
			circle = [600,800,650]/2;
		end
	end
	if strcmp(cam,'omni'); 
		omni  = get_image(0,3,'yuv');
		omni_flat = linear_unroll(omni,circle(2),circle(1),circle(3));
		[omni_stats] = find_red_candidates(omni_flat(:,:,3));
		omni_flat = ycbcr2rgb(omni_flat); 	
    omni_stats = omni_stats(1:3,:); 
		omni_stats(:,2:end) = round(omni_stats(:,2:end)/2); 
		omni_flat = omni_flat(1:2:end,1:2:end,:); 	
		rgb_image = omni_flat; 
		stats = omni_stats;  
	end
	if strcmp(cam,'front'); 
		front = get_image(1,3,'yuv');
		front = imrotate(front,180); 
		[front_stats] = find_red_candidates(front(:,:,3));
		front = ycbcr2rgb(front); 
    front_stats = front_stats(1:3,:); 
		front_stats(:,2:end) = round(front_stats(:,2:end));
		rgb_image = front; 
		stats = front_stats;  
	end
