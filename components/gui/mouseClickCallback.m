function selectPatch(obj, event)
last_click=get(gca,'CurrentPoint');
last_click=[last_click(1,2) last_click(1,1)] %y first