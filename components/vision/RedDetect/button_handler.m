function button_handler(chr,gui)
	global GLOBALS IMAGES	
	num = str2num(chr);
	GLOBALS.vision_fns.set_status(strcat('Got key: ',chr));
	if ~isempty(num) & ~strcmp(chr,'i') & ~strcmp(chr,'j') 
		if num == 0
			GLOBALS.focus = mod(GLOBALS.focus,2) + 1;
			GLOBALS.vision_fns.set_status(sprintf('Toggled focus to: %d',GLOBALS.focus)); 
			GLOBALS.vision_fns.updateBox(GLOBALS.focus);
		else 
			GLOBALS.vision_fns.set_focus(num); 
		end
	elseif strcmp(chr, '.')
		swap_out = GLOBALS.bids(GLOBALS.focus); 
		GLOBALS.vision_fns.set_focus(GLOBALS.bids(9));  
		GLOBALS.vision_fns.set_status(sprintf('Gave focus to: %d',GLOBALS.bids(GLOBALS.focus))); 
		GLOBALS.vision_fns.updateFrontFocused(GLOBALS.focus);
	elseif strcmp(chr, '*')
		GLOBALS.vision_fns.lazer_on_Callback();    
	elseif strcmp(chr, '/')
		GLOBALS.vision_fns.lazer_off_Callback();     
	elseif strcmp(chr, '+')
		GLOBALS.vision_fns.explore_Callback();    
	elseif strcmp(chr, '-')
		GLOBALS.vision_fns.stop_Callback();    
	elseif strcmp(chr, 'enter')
		GLOBALS.vision_fns.announce_ooi_Callback();    
	elseif strcmp(chr, 'del')
		GLOBALS.vision_fns.suggest_Callback();    
	elseif strcmp(chr, 'q')
		GLOBALS.vision_fns.lookat_Callback();          
	elseif strcmp(chr, 'w') 
		GLOBALS.vision_fns.track_Callback();     
	elseif strcmp(chr, 'e')
		GLOBALS.vision_fns.face_Callback();          
	elseif strcmp(chr, 'a') 
		GLOBALS.vision_fns.car_Callback();            
	elseif strcmp(chr, 's') 
		GLOBALS.vision_fns.red_ooi_Callback();     
	elseif strcmp(chr, 'd') 
		GLOBALS.vision_fns.door_Callback();          
	elseif strcmp(chr, 'z')
		GLOBALS.vision_fns.still_mobile_Callback();     
	elseif strcmp(chr, 'x')
		GLOBALS.vision_fns.yellow_ooi_Callback(); 
	elseif strcmp(chr, 'c') 
		GLOBALS.vision_fns.mobile_ooi_Callback();     
	elseif strcmp(chr, 'left') 
		GLOBALS.vision_fns.nudge_left_Callback();          
	elseif strcmp(chr, 'right'); 
		GLOBALS.vision_fns.nudge_right_Callback();          
	elseif strcmp(chr, 'up')
		GLOBALS.vision_fns.lazer_up_Callback();       
	elseif strcmp(chr, 'down')
		GLOBALS.vision_fns.lazer_down_Callback();     
	elseif strcmp(chr, 'r')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,1,1)
	elseif strcmp(chr, 't')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,1,2)
	elseif strcmp(chr, 'y')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,1,3)
	elseif strcmp(chr, 'f')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,2,1)
	elseif strcmp(chr, 'g')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,2,2)
	elseif strcmp(chr, 'h')
		GLOBALS.vision_fns.front_cand_down([],1,1,0,2,3)
	else 
		GLOBALS.vision_fns.set_status(strcat('Invalid hotkey',chr)); 
	end
