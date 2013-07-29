%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%init_cache

%warm up the cache for the polyval function
for jj=1:100
    fakepoly=rand(8,1);
    faket = rand(1);
    polyval(fakepoly,faket);
    fakepoly=rand(7,1);
    faket = rand(1);
    polyval(fakepoly,faket);
    
    faketspan = linspace(0,100);
    fakedata = rand(100,1);
    faket2 = rand(1)*100;
    yout = interp1(faketspan,fakedata,faket2,'linear','extrap');  
end