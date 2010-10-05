function button_handler(chr,gui)
	global GLOBALS IMAGES	
	GLOBALS.front_fns.set_status(strcat('Got key: ',chr)); 
	num = str2num(chr);
	if ~isempty(num)
		if num == 0
			GLOBALS.front_fns.switch_cand_Callback(); 
		else 
			GLOBALS.focus = num; 
			GLOBALS.front_fns.set_status(strcat('Switching focus to: ',chr)); 
			GLOBALS.current_bb = IMAGES(num).front_stats(GLOBALS.cand,2:end); 
			GLOBALS.front_fns.updateGui();
		end
	elseif strcmp(chr, '.')
		GLOBALS.front_fns.lookat_Callback();         
	elseif strcmp(chr, '+')
		GLOBALS.front_fns.lazer_up_Callback();       
	elseif strcmp(chr, '-')
		GLOBALS.front_fns.lazer_down_Callback();     
	elseif strcmp(chr, '*')
		GLOBALS.front_fns.lazer_on_Callback();    
	elseif strcmp(chr, '\')
		GLOBALS.front_fns.mobile_ooi_Callback();     
	elseif strcmp(chr, '/')
		GLOBALS.front_fns.lazer_off_Callback();     
	elseif strcmp(chr, 'enter')
		GLOBALS.front_fns.confirm_type_Callback();    
	elseif strcmp(chr, 'del')
		GLOBALS.front_fns.cancel_type_Callback();    
	elseif strcmp(chr, 'left')
		GLOBALS.front_fns.car_Callback();            
	elseif strcmp(chr, 'down')
		GLOBALS.front_fns.yellow_barrel_Callback(); 
	elseif strcmp(chr, 'up')
		GLOBALS.front_fns.red_barrel_Callback();     
	elseif strcmp(chr, 'right')
		GLOBALS.front_fns.door_Callback();          
	else 
		GLOBALS.front_fns.set_status(strcat('Invalid hotkey',chr)); 
	end
		

