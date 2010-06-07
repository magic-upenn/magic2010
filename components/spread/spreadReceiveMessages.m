function nmsg = spreadReceiveMessages

global SPREAD

nmsg = 0;

m = spreadAPIReceive;
while ~isempty(m),
  nmsg = nmsg + 1;

  group = m.groups;
  if isfield(SPREAD.handler,group),
    try
      SPREAD.handler.(group)(m.message);
    catch
      disp(sprintf('Error in spread %s handler: %s', group, lasterror.message));
    end
  end
  m = spreadAPIReceive;
end
