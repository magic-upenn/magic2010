function mapDisplay(event, varargin)

global GCS
global RPOSE RMAP RPATH EXPLORE_PATH
global GPOSE GMAP GPATH
global RDISPLAY GDISPLAY
global PLANDISPLAY PLANMAP PLAN_DEBUG
global MAGIC_COLORMAP
global INIT_LOG

axlim = 10;

ret = [];
switch event
  case 'entry'
    RDISPLAY.iframe = 1;

    initColormap; 

    % Setup individual robot windows
    for id = GCS.ids,
      figure(id+1);
      clf;
      set(gcf,'NumberTitle', 'off', 'Name',sprintf('Map: Robot %d',id));
      
      % Individual map
      x1 = x(RMAP{id});
      y1 = y(RMAP{id});
      RDISPLAY.hMap{id} = imagesc(x1, y1, ones(length(y1),length(x1)), [-100 100]);

      % Robot pose
      RDISPLAY.hRobot{id} = plotRobot(0, 0, 0, id);

      % Robot path
      hold on;
      RDISPLAY.path{id} = plot(0, 0, '-r');
      RDISPLAY.explore{id} = plot(0, 0, '-y');
      hold off;

      axis xy equal;
      axis([-axlim axlim -axlim axlim]);
      RDISPLAY.hAxes{id} = gca;
      set(gca,'Position', [.2 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
      set(gca,'CLim',[-100 100]); 
      set(gca,'CLimMode','manual');
      colormap(MAGIC_COLORMAP); 

      hfig = gcf;
      RDISPLAY.hFigure{id} = hfig;
      Std.Interruptible = 'off';
      Std.BusyAction = 'queue';
      RDISPLAY.stopControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Stop', ...
       'Callback', ['sendStateEvent(',num2str(id),',''stop'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .82 .15 .07]);
      RDISPLAY.backupControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Backup', ...
       'Callback', ['sendStateEvent(',num2str(id),',''backup'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .73 .15 .07]);
      RDISPLAY.spinLeftControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'SpinLeft', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinLeft'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .64 .15 .07]);
      RDISPLAY.spinRightControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'SpinRight', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinRight'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .55 .15 .07]);
      RDISPLAY.pathControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Path', ...
       'Callback', ['ginputPath(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .46 .15 .07]);
      % Button to force follow mode without obstacle detection
      RDISPLAY.forceControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Force', ...
       'Callback', ['sendStateEvent(',num2str(id),',''follow'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .37 .15 .07]);

      RDISPLAY.goToPointControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Go To Point', ...
       'Callback', ['ginputPoint(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .28 .15 .07]);
      RDISPLAY.goToPointControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Track', ...
       'Callback', ['ginputTrack(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .19 .15 .07]);
      RDISPLAY.exploreControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Explore', ...
       'Callback', ['sendStateEvent(',num2str(id),',''explore'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .10 .15 .07]);


    end


    % Setup global display window
    GDISPLAY.hFigure = figure(10);
    scrsz = get(0,'ScreenSize');
    set(GDISPLAY.hFigure,'Position',[1 scrsz(4) scrsz(3)*0.95 scrsz(4)*0.90]);
    clf;
    set(gcf,'NumberTitle', 'off', 'Name',sprintf('Global Map'));
    GDISPLAY.exploreRegions = [];
    GDISPLAY.avoidRegions = [];


    % Individual map
    x1 = x(GMAP);
    y1 = y(GMAP);
    GDISPLAY.hMap = imagesc(x1, y1, ones(length(y1),length(x1)), [-100 100]);

    % Robot poses
    for id = GCS.ids,
      GDISPLAY.hRobot{id} = plotRobot(0, 0, 0, id);
    end

    axis xy equal;
    axis([-40 40 -40 40]);
    GDISPLAY.hAxes = gca;
    set(gca,'Position', [.01 .025 .95 .95], 'XLimMode', 'manual', 'YLimMode', 'manual');
    set(gca,'CLim',[-100 100]); 
    set(gca,'CLimMode','manual');
    colormap(MAGIC_COLORMAP); 
    GDISPLAY.visualExploreOverlay = [];%patch([0],[0],[0 0 1],'Visible','off');
    GDISPLAY.visualExploreText = [];
    GDISPLAY.visualAvoidOverlay = [];%patch([0],[0],[1 0 0],'Visible','off');
    GDISPLAY.visualAvoidText = [];
    GDISPLAY.lastRegionSelection = -1;
    patch([0 1 1 0],[0 0 1 1],[0 1 0],'FaceAlpha',0.0,'EdgeAlpha',0.0);
    drawnow

    hfig = gcf;
    set(hfig, 'KeyPressFcn', @keypress);
    Std.Interruptible = 'off';
    Std.BusyAction = 'queue';
    GDISPLAY.stopControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'Callback', ['globalMapStop()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.025 .87 .15 .07]);
    GDISPLAY.goToPointControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'Callback', ['globalMapGoToPoint()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.025 .78 .15 .07]);
    GDISPLAY.exploreControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'Callback', ['globalMapExplore()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.025 .69 .15 .07]);
    GDISPLAY.exploreRegionControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'Callback', ['globalMapExploreRegion()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.025 .60 .15 .07]);
    GDISPLAY.avoidControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'Callback', ['globalMapAvoid()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.025 .51 .15 .07]);
    set(GDISPLAY.stopControl,'Units','pixels');
    set(GDISPLAY.goToPointControl,'Units','pixels');
    set(GDISPLAY.exploreControl,'Units','pixels');
    set(GDISPLAY.exploreRegionControl,'Units','pixels');
    set(GDISPLAY.avoidControl,'Units','pixels');

    buttonSize = get(GDISPLAY.stopControl,'Position');
    buttonSize = buttonSize(4:-1:3);

    stopImg = imresize(imread('quitmoving1.png'),buttonSize);
    goToPointImg = imresize(imread('waypoint1.png'),buttonSize);
    exploreImg = imresize(imread('explore1.png'),buttonSize);
    exploreRegionImg = imresize(imread('exploreregion1.png'),buttonSize);
    avoidRegionImg = imresize(imread('turnaway1.png'),buttonSize);

    set(GDISPLAY.stopControl,'CData', stopImg);
    set(GDISPLAY.goToPointControl,'CData', goToPointImg);
    set(GDISPLAY.exploreControl,'CData', exploreImg);
    set(GDISPLAY.exploreRegionControl,'CData', exploreRegionImg);
    set(GDISPLAY.avoidControl,'CData', avoidRegionImg);
    
    GDISPLAY.grp = uipanel('Parent', hfig, ...
                                'visible', 'on', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .1 .15 .4]);

    GDISPLAY.robotRadioControl{1} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 1', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .90 .5 .1]);
    GDISPLAY.robotStatusText{1} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .865 .5 .1]);
    GDISPLAY.robotRadioControl{2} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 2', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .80 .5 .1]);
    GDISPLAY.robotStatusText{2} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .765 .5 .1]);
    GDISPLAY.robotRadioControl{3} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 3', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .70 .5 .1]);
    GDISPLAY.robotStatusText{3} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .665 .5 .1]);
    GDISPLAY.robotRadioControl{4} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 4', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .60 .5 .1]);
    GDISPLAY.robotStatusText{4} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .565 .5 .1]);
    GDISPLAY.robotRadioControl{5} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 5', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .50 .5 .1]);
    GDISPLAY.robotStatusText{5} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .465 .5 .1]);
    GDISPLAY.robotRadioControl{6} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 6', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .40 .5 .1]);
    GDISPLAY.robotStatusText{6} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .365 .5 .1]);
    GDISPLAY.robotRadioControl{7} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 7', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .30 .5 .1]);
    GDISPLAY.robotStatusText{7} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .265 .5 .1]);
    GDISPLAY.robotRadioControl{8} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 8', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .20 .5 .1]);
    GDISPLAY.robotStatusText{8} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .165 .5 .1]);
    GDISPLAY.robotRadioControl{9} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'checkbox', ...
                                'String', 'Robot 9', ...
                                'KeyPressFcn', @keypress, ...
                                'Enable', 'off', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .10 .5 .1]);
    GDISPLAY.robotStatusText{9} = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'text', ...
                                'String', 'No Status', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.3 .065 .5 .1]);
    GDISPLAY.robotSelectAll = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'pushbutton', ...
                                'String', 'All', ...
                                'Callback', ['selectAll()'], ...
                                'KeyPressFcn', @keypress, ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .0 .3 .1]);
    GDISPLAY.robotSelectNone = uicontrol(Std, ...
                                'Parent', GDISPLAY.grp, ...
                                'Style', 'pushbutton', ...
                                'String', 'None', ...
                                'Callback', ['selectNone()'], ...
                                'KeyPressFcn', @keypress, ...
                                'Units', 'Normalized', ...
                                'Position', [.35 .0 .3 .1]);
    for id = GCS.ids
      set(GDISPLAY.robotRadioControl{id},'Enable','on');
    end

    GDISPLAY.cursorClickText = uicontrol(Std, ...
                                'Parent', hfig, ...
                                'Style', 'text', ...
                                'String', 'Last Click: (0,0)', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .08 .15 .02]);
    GDISPLAY.cursorDistanceText = uicontrol(Std, ...
                                'Parent', hfig, ...
                                'Style', 'text', ...
                                'String', 'Click Distance: 0', ...
                                'KeyPressFcn', @keypress, ...
                                'HorizontalAlignment','left', ...
                                'Units', 'Normalized', ...
                                'Position', [.025 .06 .15 .02]);
    GDISPLAY.last_click = [0 0];


    GDISPLAY.templateGroup = uibuttongroup('Parent', hfig, ...
                                'visible', 'on', ...
                                'Units', 'Normalized', ...
                                'SelectionChangeFcn', @radioselect, ...
                                'Position', [.80 .86 .10 .10]);

    GDISPLAY.templateControl{1} = uicontrol(Std, ...
                                'Parent', GDISPLAY.templateGroup, ...
                                'Style', 'radiobutton', ...
                                'String', 'Strong', ...
                                'KeyPressFcn', @keypress, ...
                                'Units', 'Normalized', ...
                                'Position', [.032 .66 .5 .3]);
    GDISPLAY.templateControl{2} = uicontrol(Std, ...
                                'Parent', GDISPLAY.templateGroup, ...
                                'Style', 'radiobutton', ...
                                'String', 'Moderate', ...
                                'KeyPressFcn', @keypress, ...
                                'Units', 'Normalized', ...
                                'Position', [.032 .33 .5 .3]);
    GDISPLAY.templateControl{3} = uicontrol(Std, ...
                                'Parent', GDISPLAY.templateGroup, ...
                                'Style', 'radiobutton', ...
                                'String', 'Weak', ...
                                'KeyPressFcn', @keypress, ...
                                'Units', 'Normalized', ...
                                'Position', [.032 .0 .5 .3]);
    set(GDISPLAY.templateGroup,'SelectedObject',GDISPLAY.templateControl{1});
    GDISPLAY.selectedTemplate = 1;

    GDISPLAY.exploreOverlay = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'checkbox', ...
                                        'String', 'Explore Region Overlay', ...
                                        'Callback', ['exploreRegionOverlay()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .82 .10 .03]);
    GDISPLAY.exploreRegionList = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'listbox', ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .75 .10 .07]);
    GDISPLAY.exploreRegionUpdate = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'String', 'Update', ...
                                        'Callback', ['exploreRegionUpdate()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.90 .785 .05 .035]);
    GDISPLAY.exploreRegionDelete = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'String', 'Delete', ...
                                        'Callback', ['exploreRegionDelete()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.90 .75 .05 .035]);

    GDISPLAY.avoidOverlay = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'checkbox', ...
                                        'String', 'Avoid Region Overlay', ...
                                        'Callback', ['avoidRegionOverlay()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .70 .10 .03]);
    GDISPLAY.avoidRegionList = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'listbox', ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .63 .10 .07]);
    GDISPLAY.avoidRegionDelete = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'String', 'Delete', ...
                                        'Callback', ['avoidRegionDelete()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.90 .63 .05 .035]);

    GDISPLAY.UAVOverlay = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'checkbox', ...
                                        'String', 'UAV Overlay', ...
                                        'Callback', ['UAVOverlay()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .58 .10 .03]);

    GDISPLAY.gridOverlay = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'checkbox', ...
                                        'String', 'Grid Overlay', ...
                                        'Callback', ['gridOverlay()'], ...
                                        'KeyPressFcn', @keypress, ...
                                        'Units', 'Normalized', ...
                                        'Position', [.80 .55 .10 .03]);

    if PLAN_DEBUG
      PLANDISPLAY.fig = figure(11);
      clf;
      set(gcf,'NumberTitle', 'off', 'Name',sprintf('Plan Map'));
      PLANDISPLAY.map = imagesc(PLANMAP.map);
      axis xy equal;
      GDISPLAY.hAxes = gca;
      set(gca,'Position', [.1 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
      colormap(jet);
      drawnow
    end

  case 'update'
    RDISPLAY.iframe = RDISPLAY.iframe + 1;

    for id = GCS.ids,
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

      if ~isempty(RPATH{id})
        hold on;
        set(RDISPLAY.path{id},'x',RPATH{id}.x,'y',RPATH{id}.y);
        hold off;
      end

      if ~isempty(EXPLORE_PATH{id})
        hold on;
        set(RDISPLAY.explore{id},'x',EXPLORE_PATH{id}.x,'y',EXPLORE_PATH{id}.y);
        hold off;
      end
        
      if ~isempty(GPOSE{id}),
        plotRobot(GPOSE{id}.x, GPOSE{id}.y, GPOSE{id}.yaw, id, GDISPLAY.hRobot{id});
      end

    end

    cost = getdata(GMAP, 'cost');
    set(GDISPLAY.hMap, 'CData', cost');

    new_pos = get(GDISPLAY.hAxes,'CurrentPoint');
    new_pos = new_pos(1,1:2);
    if sum(GDISPLAY.last_click ~= new_pos) == 2
      set(GDISPLAY.cursorClickText,'String', ['Last Click: (',num2str(new_pos(1)),',',num2str(new_pos(2)),')']);
      set(GDISPLAY.cursorDistanceText,'String', ['Click Distance: ',num2str(sqrt(sum((new_pos-GDISPLAY.last_click).^2)))]);
      GDISPLAY.last_click = new_pos;
    end

    if PLAN_DEBUG
      %set(PLANDISPLAY.map, 'CData', PLANMAP.map);
      if(PLANMAP.new == 1)
        figure(11);
        PLANDISPLAY.map = imagesc(PLANMAP.map);
        axis xy;
        PLANMAP.new = 0;
      end
    end
    

    drawnow;


  case 'exit'
end

