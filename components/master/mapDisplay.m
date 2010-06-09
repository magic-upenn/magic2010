function mapDisplay(event, varargin)

global RPOSE RMAP
global RDISPLAY

axlim = 10;

ret = [];
switch event
  case 'entry'
    RDISPLAY.iframe = 1;
    for id = [1:length(RPOSE)],
      if isempty(RPOSE{id}), continue, end;

      figure(id);
      clf;
      set(gcf,'NumberTitle', 'off', 'Name',sprintf('Map: Robot %d',id));
      
      % Individual map
      x1 = x(RMAP{id});
      y1 = y(RMAP{id});
      RDISPLAY.hMap{id} = imagesc(x1, y1, ones(length(y1),length(x1)), [-100 100]);

      % Robot pose
      RDISPLAY.hRobot{id} = plotRobot(0, 0, 0, id);

      axis xy equal;
      axis([-axlim axlim -axlim axlim]);
      RDISPLAY.hAxes{id} = gca;
      set(gca,'Position', [.2 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
      colormap(jet);

      hfig = gcf;
      Std.Interruptible = 'off';
      Std.BusyAction = 'queue';
      RDISPLAY.pathControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Path', ...
       'Callback', ['ginputPath(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .85 .15 .075]);
      RDISPLAY.backupControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Backup', ...
       'Callback', ['sendStateEvent(',num2str(id),',''backup'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .75 .15 .075]);
      RDISPLAY.spinLeftControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Spin Left', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinLeft'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .65 .15 .075]);
      RDISPLAY.spinRightControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Spin Right', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinRight'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .55 .15 .075]);

    end

    drawnow

  case 'update'
    RDISPLAY.iframe = RDISPLAY.iframe + 1;

    for id = [1:length(RPOSE)],
      if isempty(RPOSE{id}), continue, end;
      
      map1 = RMAP{id};
      cost = getdata(map1, 'cost');
      set(RDISPLAY.hMap{id}, 'CData', cost');

      if ~isempty(RPOSE{id}),
        xp = RPOSE{id}.x;
        yp = RPOSE{id}.y;
        ap = RPOSE{id}.yaw;
        plotRobot(xp, yp, ap, id, RDISPLAY.hRobot{id});

        shiftAxes(RDISPLAY.hAxes{id}, xp, yp);
      end
    end

    drawnow;


  case 'exit'
end

