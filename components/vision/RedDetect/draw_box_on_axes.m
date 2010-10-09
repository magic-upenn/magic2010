function img = draw_box_on_axes(bb,color,axeh)
	if numel(bb) ~= 4
		return
	end
	line([bb(3),bb(4)],[bb(1),bb(1)],'Color',color,'LineWidth',2,'Parent',axeh);
	line([bb(3),bb(4)],[bb(2),bb(2)],'Color',color,'LineWidth',2,'Parent',axeh);
	line([bb(3),bb(3)],[bb(1),bb(2)],'Color',color,'LineWidth',2,'Parent',axeh);
	line([bb(4),bb(4)],[bb(1),bb(2)],'Color',color,'LineWidth',2,'Parent',axeh);
