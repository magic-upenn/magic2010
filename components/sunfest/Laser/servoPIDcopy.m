clear; clf;
angleT = 3/4*pi; angleS2 = pi/4;
wT = 0;
wS2 = 0;
dt = 0.03;
counter = 0;
wTmax = 1.27;
wSmax = deg2rad(100);
accelSmax = deg2rad(300);
accelS2ramp = deg2rad(100);

subplot(1,2,1);
polar(0,1.5); hold on;
hS = polar([angleS2 angleS2], [0 1]);
hT = polar(angleT,1,'or');

subplot(1,2,2);
plot([0 10e3],[0 0],'k'); hold on;
hE = plot(0,0);

time = [0:dt:10e3];
error = zeros(1,length(time));

%axes([0 10 -180 180]);
while(1)
	counter = counter + 1;
	if ~mod(counter-1,150)
		accelT = 3*(rand-0.5);
	end
	
	wT = wT + accelT*dt;
	
	if wT > wTmax
		wT = wTmax;
	elseif wT < -wTmax
		wT = -wTmax;
	end
	
	angleT = angleT + wT*dt;
	
	dAngle2 = angleT-angleS2;
	dAngle2 = mod(dAngle2,2*pi);
	if dAngle2 > pi
		dAngle2 = dAngle2 - 2*pi;
	elseif dAngle2 < -pi
		dAngle2 = dAngle2 + 2*pi;
	end
	
	error(counter) = dAngle2;
	
	wSdes2 = 10*sqrt(2*wSmax*abs(dAngle2));
	if wSdes2 > wSmax,	wSdes2 = wSmax; end
	if dAngle2 < 0, wSdes2 = -wSdes2; end
	
	accelS2 = (wSdes2 - wS2)/dt;
	if accelS2 > accelSmax
		accelS2 = accelSmax;
	elseif accelS2 < -accelSmax
		accelS2 = -accelSmax;
	end
	
	wS2 = wS2 + accelS2*dt;
	angleS2 = angleS2 + wS2*dt + 1/2*accelS2*dt^2;
	
	set(hT,'xdata',cos(angleT),'ydata',sin(angleT));
	set(hS,'xdata',[0 cos(angleS2)],'ydata',[0 sin(angleS2)]);
	set(hE,'xdata',time(1:counter),'ydata',error(1:counter));
	axis([max(0,time(counter)-3) max(time(counter),3) -pi/2 pi/2]);

	drawnow;
	pause(dt);
end