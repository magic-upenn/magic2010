function imout = undistort(imin, params)
    fx = params.fx;
    fy = params.fy;
    cx = params.cx;
    cy = params.cy;
    k1 = params.k1;
    k2 = params.k2;
    k3 = params.k3;
    p1 = params.p1;
    p2 = params.p2;
    
    K = [fx 0 cx; 0 fy cy; 0 0 1];
    
    imout = zeros(size(imin));
    [i j] = find(~isnan(imin));
    
    Xp = inv(K)*[j i ones(length(i),1)]';
    
    r2 = Xp(1,:).^2+Xp(2,:).^2;
    x = Xp(1,:);
    y = Xp(2,:);
    
    x = x.*(1+k1*r2+k2*r2.^2) + 2*p1.*x.*y + p2*(r2+2*x.^2);
    y = y.*(1+k1*r2+k2*r2.^2) + 2*p2.*x.*y + p1*(r2+2*y.^2);
    
    u=reshape(fx*x + cx, size(imout));
    v=reshape(fy*y + cy, size(imout));
    
    imout = interp2(imin,u,v);
end