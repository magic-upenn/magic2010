function gcsRecvIncMapUpdateH(data, name)

global RMAP
global GPOSE GTRANSFORM GMAP


if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got horizontal map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'hlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);

if ~isempty(GPOSE{id}),
  [xg, yg] = rpos_to_gpos(id, xm, ym);

  % Hierarchical slam:
  if ~GTRANSFORM{id}.init,
    disp(sprintf('Computing initial slam for robot %d',id));
    xs = [-5:.25:5];
    ys = [-5:.25:5];
    as = [-50:1:50]*pi/180;

    %{
    xs = 0;
    ys = 0;
    as = 0;
    %}
    GTRANSFORM{id}.init = 1;
  else
    xs = 0;
    ys = 0;
    as = 0;
    %{
    xs = [-.2:.1:.2];
    ys = [-.2:.1:.2];
    as = [-1:.5:1]*pi/180;
    %}
  end

  [xm, ym, am, cmax] = mapMatch(GMAP, 'hlidar', xg, yg, xs, ys, as);

  cyaw = cos(GTRANSFORM{id}.dyaw);
  syaw = sin(GTRANSFORM{id}.dyaw);
  Told = [cyaw -syaw GTRANSFORM{id}.dx; syaw cyaw GTRANSFORM{id}.dy; 0 0 1];

  Tmatch = [cos(am) -sin(am) xm; sin(am) cos(am) ym; 0 0 1];
  Tnew = Told*inv(Tmatch);

  GTRANSFORM{id}.dx = Tnew(1,3);
  GTRANSFORM{id}.dy = Tnew(2,3);
  GTRANSFORM{id}.dyaw = GTRANSFORM{id}.dyaw - am;

  NotViewed = NotViewedByAnotherRobot(id, xg, yg);
  
  xg = xg(NotViewed);
  yg = yg(NotViewed);
  cm = cm(NotViewed);
  
  asgn(GMAP, 'hlidar', xg, yg, cm);
  asgn(GMAP, 'cost', xg, yg, cm);
  
end
