function gcsUpdateIPC

global GCS
global RPOSE RMAP
global GPOSE GMAP GTRANSFORM
global EXPLORE_REGIONS AVOID_REGIONS OOI
global ROBOT_PATH OOI_PATH NC_PATH
global MAGIC_CONSTANTS

% Non blocking receive:
masterReceiveFromRobots();
GetLocalMsg();

if (gettime - GCS.tSave > 60)
  savefile = ['/tmp/gcs_', datestr(clock,30)];
  disp(sprintf('Saving log file: %s', savefile));
  eval(['save ' savefile ' RPOSE RMAP GPOSE GMAP GTRANSFORM EXPLORE_REGIONS AVOID_REGIONS OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS']);
  GCS.tSave = gettime;
end

% See if map needs to be shifted:
for id = GCS.ids,
  mx0 = RMAP{id}.x0;
  my0 = RMAP{id}.y0;
  if (abs(RPOSE{id}.x - mx0) > 15.0) || ...
    (abs(RPOSE{id}.y - my0) > 15.0),

    % Current limits:
    xlim = RMAP{id}.x0+RMAP{id}.dx;
    ylim = RMAP{id}.y0+RMAP{id}.dy;
    [nx, ny] = size(RMAP{id}.cost);
    x1 = [xlim(1): (xlim(end)-xlim(1))/(nx-1): xlim(end)];
    y1 = [ylim(1): (ylim(end)-ylim(1))/(ny-1): ylim(end)];

    % Points array:
    [xc, yc, sc] = find(RMAP{id}.cost);
    pc = [x1(xc); y1(yc); double(sc)'];

    % New limits:
    RMAP{id}.x0 = RPOSE{id}.x;
    RMAP{id}.y0 = RPOSE{id}.y;
    RMAP{id}.cost = zeros(nx, ny, 'int8');
    map_assign(RMAP{id}.cost, ...
               RMAP{id}.x0+RMAP{id}.dx, RMAP{id}.y0+RMAP{id}.dy, ...
               pc);
    
    disp(sprintf('rmap %d shift', id));
  end
end

end

function GetLocalMsg
global gcs_machine
global IPC
msgs = gcs_machine.ipcAPI('listenWait',100);
%gcsLogPackets('LocalIPC',msgs);
nmsg = length(msgs);
%process messages
for mi=1:nmsg
    name = msgs(mi).name;
    name(name=='/')='_';
    if isfield(IPC.handler,name),
      IPC.handler.(name)(msgs(mi).data,msgs(mi).name);
    else
      warning('no handler for message name %s',msgs(mi).name);
    end
end
end



