function y = spreadAPIReceive;

if spreadAPIPoll == 0,
  y = [];
  return;
end

y = spreadAPI('receive');
