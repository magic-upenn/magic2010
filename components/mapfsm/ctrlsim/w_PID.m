function [w_out] = w_PID(heading_curr, heading_des)
% fxn takes current heading (+ being CCW, - being CW), desired heading and returns updated w
% (negative w is turn to the right, positive is turn to the left)
persistent time_prev error_prev error_sum;

% gains
Kp = 5*(1/pi);  
Ki = 5;
Kd = 0.1;

% constants
anti_wind_up = pi; % max integral term
decay = .3; % diminishes old integral terms
%turn_rate = 3; % turn rate in radians per second

% grab time
time_curr = minute(now)*60 + second(now);

% initialize if first time running
if (isempty(time_prev))
    dt = 1;
    error_prev = 0; %heading_prev = heading_curr;
    error_sum = 0;
else
    dt = time_curr - time_prev;
    if ((dt > 20)||(dt <= 0))  % really?  do you want a control input based on a 20 second old measurement?
        Kp = 0;
        Ki = 0;
        Kd = 0;
        dt = 1;
    end
    
end
% calculate and normalize heading error
heading_error = (heading_des - heading_curr);
heading_error = mod(heading_error, 2*pi);
if (heading_error > pi)
    heading_error = heading_error - 2*pi;
end

% if (sign(error_prev) ~= sign(heading_error))
%     error_sum = 0;
% end
%error_sum = decay*error_sum;


% check anti-windup
if (abs(error_sum) < anti_wind_up)
    error_sum = error_sum + (heading_error*dt);
end
% and clip
if (abs(error_sum) > anti_wind_up)
    error_sum = anti_wind_up * sign(error_sum);
end

% derivative term
heading_rate = (heading_error - error_prev)/dt;

% cap PID effects?


% the actual PID formula  original gets 70% weight, PID gets 30%
w_out =  (heading_error * Kp) + (error_sum * Ki) + (heading_rate * Kd);

% display for testing
fprintf('he: % 2.3f\tes: % 2.3f\thr: % 2.3f\tp: % 2.3f\ti: % 2.3f\td: % 2.3f\tw: % 2.3f\tdt: % 2.5f\n', heading_error, error_sum,heading_rate,(heading_error * Kp), (error_sum * Ki), (heading_rate * Kd), w_out, dt);

% close out for next iteration
error_prev = heading_error;
time_prev = time_curr;


end


