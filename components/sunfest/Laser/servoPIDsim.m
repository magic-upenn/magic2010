function servoPIDsim

	%%%%%%%%%%%%%%%%%%%%%%%%%%
	% PID Control Contstants %
	%%%%%%%%%%%%%%%%%%%%%%%%%%	
	bufferTime		= 2; %time (s) to keep track of servo and target angle history
	kP						= 6;
	kI						= 2;
	kD						= .5;
	%%%%%%%%%%%%%%%%%%%%%%%%%%

	%%%%%%%%%%%%%%%%%%%%%%%%
	% Simulation Constants %
	%%%%%%%%%%%%%%%%%%%%%%%%
	accDuration		= 4;  %time (s) between random target acceleration assigments
	dt = 0.025;
									%pos				vel						acc
	targetState		=	[3/4*pi			0							0							];
	servoState		= [1/4*pi			0							0							];
	targetBounds	=	[Inf				1.3						6							];
	servoBounds		= [Inf				deg2rad(100)	deg2rad(300)	];
	%%%%%%%%%%%%%%%%%%%%%%%%
	
	clf;
	polar(0,1.5)
	hold on;
	targetHandle		= plot(0,0,'or','MarkerSize',10,'MarkerFaceColor','r');
	servoHandle			= plot(0,0,'k','LineWidth',3);
	plot(0,0,'ok','MarkerSize',10,'MarkerFaceColor','k');

	bufferLength	= round(bufferTime/dt);
	angleBuffer = zeros(2,bufferLength);

	for counter=1:Inf
		
		targetState			= updateTarget(targetState,targetBounds,dt,accDuration,counter);
		angleBuffer			= updateBuffer(angleBuffer,targetState(1),servoState(1));
		vDesired				= PIDcontrol(angleBuffer,kP,kI,kD,dt);
		servoState			= updateServo(servoState,servoBounds,dt,vDesired);
		
		updatePlots(targetState(1),servoState(1),targetHandle,servoHandle);
		
		pause(dt);
		
	end
	
end

function targetState = updateTarget(targetState,targetBounds,dt,accDuration,counter)

	x = targetState(1);
	v = targetState(2);
	a = targetState(3);
	
	X = targetBounds(1);
	V = targetBounds(2);
	A = targetBounds(3);
	
	numSteps = round(accDuration/dt);
	
	if ~mod(counter,numSteps)
		a = A*(2*rand-1);
	end
		
	v = v + a*dt;

	if v > V
		v = V;
	elseif v < -V
		v = -V;
	end
	
	x = x + v*dt;
	
	targetState = [x v a];

end

function angleBuffer = updateBuffer(angleBuffer,targetAngle,servoAngle)

	angleBuffer(:,2:end)	= angleBuffer(:,1:end-1);
	angleBuffer(1,1)			= targetAngle;
	angleBuffer(2,1)			= servoAngle;

end

function desiredVel = PIDcontrol(angleBuffer,kP,kI,kD,dt)

	proportional     = kP * (angleBuffer(1,1)-angleBuffer(2,1));
	integral         = kI * sum((angleBuffer(1,:)-angleBuffer(2,:))*dt);
	differential     = kD * ((angleBuffer(1,1)-angleBuffer(2,1)) - (angleBuffer(1,2)-angleBuffer(2,2)))/dt;
	desiredVel			 = proportional + integral + differential;
		
end

function servoState = updateServo(servoState,servoBounds,dt,vDesired)

	x = servoState(1);
	v = servoState(2);
	a = servoState(3);
	
	X = servoBounds(1);
	V = servoBounds(2);
	A = servoBounds(3);

	a = (vDesired-v)/dt;

	if a > A
		a = A;
	elseif a < -A
		a = -A;
	end

	v = v + a*dt;
	x = x + v*dt + 1/2*a*dt^2;
	
	servoState = [x v a];

end

function updatePlots(xT,xS,hT,hS)

	set(hS,'xdata',[0 cos(xS)],'ydata',[0 sin(xS)]);
	set(hT,'xdata',cos(xT),'ydata',sin(xT));
	drawnow;

end