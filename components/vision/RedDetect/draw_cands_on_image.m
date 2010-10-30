function draw_cands_on_image(imh,axeh,stats,img)
	set(imh,'CData',img);
	delete(findobj(get(axeh,'Children'),'Type','Rectangle')); 
	delete(findobj(get(axeh,'Children'),'Type','Line')); 
	if isempty(stats)
		return
	end
	stats = flipud(sortrows(stats,1));  
	for i = 1:min(size(stats,1),3)
		linecolor = 'blue';
		if i == 3
			linecolor = 'red';
		end
		if i == 2
			linecolor = 'yellow';
		end
		if i == 1
			linecolor = 'green';
		end
		bb = stats(i,2:end);
		bb = max(bb,1);  
		if bb(4)-bb(3) == 0 || bb(2)-bb(1) == 0
			continue
		end
		rectangle('Position',[bb(3),bb(1),bb(4)-bb(3),bb(2)-bb(1)],'EdgeColor',linecolor,'LineWidth',2,'Parent',axeh,'HitTest','off'); 
%		line([bb(3),bb(4)],[bb(1),bb(1)],'Color',linecolor,'LineWidth',2,'Parent',axeh);
%		line([bb(3),bb(4)],[bb(2),bb(2)],'Color',linecolor,'LineWidth',2,'Parent',axeh);
%		line([bb(3),bb(3)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2,'Parent',axeh);
%		line([bb(4),bb(4)],[bb(1),bb(2)],'Color',linecolor,'LineWidth',2,'Parent',axeh);
	end
