function status = spreadInit

global SPREAD
if isempty(SPREAD),
  [SPREAD.mbox, SPREAD.private_group] = spreadAPIConnect;
end

status = true;

disp('Spread initialized');
