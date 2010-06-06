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

      x1 = x(RMAP{id});
      y1 = y(RMAP{id});
      RDISPLAY.hMap{id} = imagesc(x1, y1, ones(length(y1),length(x1)), [-1 1]);

      plotRobot(0, 0, 0, id);

      axis xy equal;
      axis([-axlim axlim -axlim axlim]);
      RDISPLAY.hAxes{id} = gca;
      set(gca,'XLimMode', 'manual', 'YLimMode', 'manual');
      colormap(jet);
    end

    drawnow

  case 'update'
    RDISPLAY.iframe = RDISPLAY.iframe + 1;

    for id = [1:length(RPOSE)],
      if isempty(RPOSE{id}), continue, end;
      
      map1 = RMAP{id};
      costh = getdata(map1, 'hlidar');
      array_threshold(costh,-1,1);
      costv = getdata(map1, 'vlidar');
      array_threshold(costv,-1,1);
      cost = costh + 2*costv;
      set(RDISPLAY.hMap{id}, 'CData', cost');

      if ~isempty(RPOSE{id}.data),
        xp = RPOSE{id}.data.x;
        yp = RPOSE{id}.data.y;
        ap = RPOSE{id}.data.yaw;
        plotRobot(xp, yp, ap, id);

        shiftAxes(RDISPLAY.hAxes{id}, xp, yp);
      end
    end

    drawnow;


  case 'exit'
end

