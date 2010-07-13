clear; clf;
angleT = 3/4*pi; angleS = pi/4; angleS2 = angleS;
wT = 0;
wS = 0; wS2=0;
dt = 0.03;
counter = 0;
wTmax = 1.27;
wSmax = deg2rad(100);
accelSmax = deg2rad(300);
dAnglePrev = 0;

subplot(1,2,1);
polar(0,1.5); hold on;
hS = polar([angleS angleS], [0 1]);
hS2= polar([angleS2 angleS2], [0 1],'k');
hT = polar(angleT,1,'or');

subplot(1,2,2);
plot([0 10e3],[0 0],'k'); hold on; grid off;
hE = plot(0,0);

time = [0:dt:10e3];
error = zeros(1,length(time));

%axes([0 10 -180 180]);
while(counter<300/dt)
	counter = counter + 1;
	if ~mod(counter-1,150)
		accelT = 3*(rand-0.5);
		if accelT > 0 && accelT < 1
			accelT = 1;
		elseif accelT < 0 && accelT > -1
			accelT = -1;
		end
	end
	
	wT = wT + accelT*dt;
	
	if wT > wTmax
		wT = wTmax;
	elseif wT < -wTmax
		wT = -wTmax;
	end
	
	angleT = angleT + wT*dt;
	
	dAngle = angleT-angleS;
	dAngle = mod(dAngle,2*pi);
	if dAngle > pi
		dAngle = dAngle - 2*pi;
	elseif dAngle < -pi
		dAngle = dAngle + 2*pi;
	end
	
	proErr = 2 * dAngle;
	intErr = sum(error(max(1,counter-30):counter))*dt;
	difErr = (dAngle-dAnglePrev)/dt;
	
	error(counter) = proErr + intErr + difErr;
	
	wSdes = error(counter);
	
	accelS = (wSdes-wS)/dt;
	
	if accelS > accelSmax
		accelS = accelSmax;
	elseif accelS < -accelSmax
		accelS = -accelSmax;
	end
	
	wS = wS + accelS*dt;
	angleS = angleS + wS*dt + 1/2*accelS*dt^2;
	
	% Current Servo Controller
	dAngle2 = angleT-angleS2;
	dAngle2 = mod(dAngle2,2*pi);
	if dAngle2 > pi
		dAngle2 = dAngle2 - 2*pi;
	elseif dAngle2 < -pi
		dAngle2 = dAngle2 + 2*pi;
	end
	
	wSdes2 = sqrt(2*wSmax*abs(dAngle2));
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
	set(hS2,'xdata',[0 cos(angleS2)],'ydata',[0 sin(angleS2)]);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	set(hT,'xdata',cos(angleT),'ydata',sin(angleT));
	set(hS,'xdata',[0 cos(angleS)],'ydata',[0 sin(angleS)]);
	set(hE,'xdata',time(1:counter),'ydata',error(1:counter));
	axis([max(0,time(counter)-3) max(time(counter),3) -pi/2*10 pi/2*10]);
	set(gca,'XTick',0);
	drawnow;
	
	dAnglePrev = dAngle;
	pause(dt);
end