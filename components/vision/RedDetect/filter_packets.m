function [packets,ids] = filter_packets(packets)
	isfront = logical(zeros(1,numel(packets))); 
	time    = zeros(1,numel(packets)); 
	id 	= zeros(1,numel(packets));
	ind     = 1:numel(packets);  
	for i = 1:numel(packets)
		packet = packets{i}; 
		isfront(i) = strcmp(packet.type,'FrontVision');
		time(i) = packet.t; 
		id(i) = packet.id; 
	end
	ind_front  = ind(isfront);
	time_front = time(isfront); 
	id_front   = id(isfront); 
	ind_omni  = ind(~isfront);
	time_omni = time(~isfront);
	id_omni   = id(~isfront);
	keep = []; 
	for i = 1:9
		front_i = (id_front == i);
		omni_i = (id_omni == i);
		if any(front_i)
			ind_front_i  = ind_front(front_i);  
			[tfv,tfi] = sort(time_front(front_i));
			keep = [keep, ind_front_i(tfi(end))];
		end
		if any(omni_i)
			ind_omni_i  = ind_omni(omni_i);
			[tov,toi] = sort(time_omni(omni_i));
			keep = [keep, ind_omni_i(toi(end))]; 
		end
	end
	sprintf('In %d, Out %d',numel(packets),numel(keep))
	packets = {packets{keep}};
	ids = unique(id);  
