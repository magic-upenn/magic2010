function data = trimmed_data(data,pcnt)
	pcnt = pcnt/100;
	rem = (1 - pcnt )/2; 
	rl = round(numel(data) .* rem);  
	ru = round(numel(data) .* (1-rem));  
	data = sort(data); 
	data = data(rl:ru); 
	
