function button_handler(chr,gui)
	global GLOBALS IMAGES	
	num = str2num(chr);
	if strcmp(gui,'track')
		if ~isempty(num)
			num
			if num == 0
				GLOBALS.track_fns.toggle_control(); 	
			else
				GLOBALS.track_fns.set_robot(num); 	
			end
		elseif strcmp(chr, '.')
		elseif strcmp(chr, '+')
		elseif strcmp(chr, '-')
		elseif strcmp(chr, '*')
		elseif strcmp(chr, '|')
		elseif strcmp(chr, '\')
		elseif strcmp(chr, '/')
		elseif strcmp(chr, 'enter')
		elseif strcmp(chr, 'del')
		elseif strcmp(chr, 'left')
			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,1]); 
		elseif strcmp(chr, 'down')
			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,2]); 
		elseif strcmp(chr, 'up')
			focus = GLOBALS.track_toggle; 
			id = GLOBALS.track_focus(focus).id;
			cand = GLOBALS.track_focus(focus).cand;
			x = mean(IMAGES(id).front_stats(cand,4:5));
			po = front_pixel_to_omni(IMAGES(id).omni,IMAGES(id).front,x); 
			angle = pixel_to_angle(IMAGES(id).omni,po);
			GLOBALS.front_fns.lookat(GLOBALS.focus, angle,'track');  
		elseif strcmp(chr, 'right')
			GLOBALS.track_fns.set_cand([],[],[],[GLOBALS.track_toggle,3]); 
		elseif strcmp(chr, 'w') | strcmp(chr,'['); 
		elseif strcmp(chr, 'v') | strcmp(chr,']'); 
		else 
		end
	else 
		GLOBALS.front_fns.set_status(strcat('Got key: ',chr)); 
		if ~isempty(num)
			if num == 0
				GLOBALS.front_fns.switch_cand_Callback(); 
				GLOBALS.omni_fns.updateGui();
			else 
				GLOBALS.focus = num; 
				GLOBALS.front_fns.set_status(strcat('Switching focus to: ',chr)); 
				GLOBALS.current_bb = IMAGES(num).front_stats(GLOBALS.cand,2:end); 
				GLOBALS.front_fns.updateGui();
				GLOBALS.omni_fns.updateGui();
			end
		elseif strcmp(chr, '.')
			GLOBALS.front_fns.lookat_Callback();         
		elseif strcmp(chr, '+')
			GLOBALS.front_fns.lazer_up_Callback();       
		elseif strcmp(chr, '-')
			GLOBALS.front_fns.lazer_down_Callback();     
		elseif strcmp(chr, '*')
			GLOBALS.front_fns.lazer_on_Callback();    
		elseif strcmp(chr, '|')
			GLOBALS.front_fns.still_mobile_Callback();     
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
			GLOBALS.front_fns.yellow_ooi_Callback(); 
		elseif strcmp(chr, 'up')
			GLOBALS.front_fns.red_ooi_Callback();     
		elseif strcmp(chr, 'right')
			GLOBALS.front_fns.door_Callback();          
		elseif strcmp(chr, 'w') | strcmp(chr,'['); 
			GLOBALS.front_fns.nudge_left_Callback();          
		elseif strcmp(chr, 'v') | strcmp(chr,']'); 
			GLOBALS.front_fns.nudge_right_Callback();          
		else 
			GLOBALS.front_fns.set_status(strcat('Invalid hotkey',chr)); 
		end
	end	

