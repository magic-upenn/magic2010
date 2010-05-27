function mouseClickCallback(obj, event)
global USER_INPUT

USER_INPUT.fresh = 1;
last_click=get(gca,'CurrentPoint');
USER_INPUT.x = last_click(1,2);
USER_INPUT.y = last_click(1,1);
