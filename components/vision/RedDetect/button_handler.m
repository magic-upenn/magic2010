function button_handler(chr,gui)
	global FRONT_GUI OMNI_GUI FRONT_FNS OMNI_FNS	
	FRONT_FNS.set_status(strcat('Got key: ',chr)); 
	num = str2num(char); 
	if ~isempty(num)
		FRONT_FNS.switch_cand_Callback();    
		if num == 0
		else 
			FOCUS = num; 
			FRONT_FNS.updateGuii();
		end
	elseif strcmp(chr, '.')
		FRONT_FNS.lookat_Callback();         
	elseif strcmp(chr, '+')
		FRONT_FNS.lazer_up_Callback();       
	elseif strcmp(chr, '-')
		FRONT_FNS.lazer_down_Callback();     
	elseif strcmp(chr, '*')
		FRONT_FNS.lazer_on_Callback();    
	elseif strcmp(chr, '\')
		FRONT_FNS.mobile_ooi_Callback();     
	elseif strcmp(chr, '/')
		FRONT_FNS.lazer_off_Callback();     
	elseif strcmp(chr, 'enter')
		FRONT_FNS.confirm_type_Callback();    
	elseif strcmp(chr, 'del')
		FRONT_FNS.cancel_type_Callback();    
	elseif strcmp(chr, 'left')
		FRONT_FNS.car_Callback();            
	elseif strcmp(chr, 'down')
		FRONT_FNS.yellow_barrel_Callback(); 
	elseif strcmp(chr, 'up')
		FRONT_FNS.red_barrel_Callback();     
	elseif strcmp(chr, 'right')
		FRONT_FNS.door_Callback();           
	end
		

