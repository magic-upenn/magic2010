function s = cam(command,cam_index)
	persistent current;
	if exist('cam_index')
		current = cam_index;
	end 
	s = sprintf('%d_%s',current,command); 
