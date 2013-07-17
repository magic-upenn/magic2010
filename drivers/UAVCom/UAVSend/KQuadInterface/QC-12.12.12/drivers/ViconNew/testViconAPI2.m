%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
host = 'alkaline';
ViconAPI2('connect',host);


while(1)
  vdata = ViconAPI2('get_data')
  %fprintf('----------------------------\n');
  usleep(10000);
end

