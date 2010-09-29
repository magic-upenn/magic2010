function [w_out] = w_PID(heading_curr, heading_des, x, y, path_pts)
% fxn takes current heading (+ being CCW, - being CW), desired heading and returns updated w
% (negative w is turn to the right, positive is turn to the left)
% (negative offset is to the left, positive is to the right)
persistent time_prev error_prev error_sum offset_prev offset_sum;

%path_pts

% gains
Khp = 2.5/pi; 
Khi = 0.1;
Khd = 0.5;
Kop = 0;%0.5;
Koi = 0;%1;
Kod = 0;%0.05;

% constants
anti_wind_up_head = 3*pi; % max integral term
anti_wind_up_offset = 2;
%decay = .3; % diminishes old integral terms
%turn_rate = 3; % turn rate in radians per second

% grab time
time_curr = minute(now)*60 + second(now);

% initialize if first time running
if (isempty(time_prev))
    dt = 1;
    error_prev = 0; %heading_prev = heading_curr;
    error_sum = 0;
    offset_prev = 0;
    offset_sum =0;
else
    dt = time_curr - time_prev;
    if ((dt > 20)||(dt <= 0))  % really?  do you want a control input based on a 20 second old measurement?
        Khp = 0;
        Khi = 0;
        Khd = 0;
        Kop = 0;
        Koi = 0;
        Kod = 0;
        dt = 1;
    end
end

% calculate and normalize heading error
heading_error = (heading_des - heading_curr);
heading_error = mod(heading_error, 2*pi);
if (heading_error > pi)
    heading_error = heading_error - 2*pi;
end

 if (sign(error_prev) ~= sign(heading_error))
     error_sum = 0;
 end
%error_sum = decay*error_sum;

% check anti-windup
if (abs(error_sum) <= anti_wind_up_head)
    error_sum = error_sum + (heading_error*dt);
end
% and clip
if (abs(error_sum) > anti_wind_up_head)
    error_sum = anti_wind_up_head * sign(error_sum);
end

% derivative term
heading_rate = (heading_error - error_prev)/dt;

% position error calcs
xnext1 = path_pts(1,1);
ynext1 = path_pts(1,2);
xnext2 = path_pts(2,1);
ynext2 = path_pts(2,2);
%disp([xnext2 ynext2]);

ext_path = [xnext2-xnext1 ynext2-ynext1];
vec2path = [x-xnext1 y-ynext1];
dis2start = dot(vec2path, ext_path);
dis2end = dot(ext_path, ext_path);
b = dis2start/dis2end;
Pb = [xnext1 ynext1] + b * ext_path;
% phi = atan2(ynext2-y, xnext2-x);
% if phi>pi
%     phi = phi-2*pi;
% end

theta = atan2(y-ynext1, x-xnext1);
phi = atan2(ynext2-ynext1, xnext2-xnext1);
dir = sign(sin(phi-theta));

% proportional term
offset_error = sqrt((x-Pb(1))^2 + (y-Pb(2))^2)*dir;

% check anti-windup
if (abs(offset_sum) <= anti_wind_up_offset)
    offset_sum = offset_sum + (offset_error*dt);
end
% and clip
if (abs(offset_sum) > anti_wind_up_offset)
    offset_sum = anti_wind_up_offset * sign(offset_sum);
end

 if (sign(offset_prev) ~= sign(offset_error))
     offset_sum = 0;
 end


% derivative term
offset_rate = (offset_error - offset_prev)/dt;

% the actual PID formula  original gets 70% weight, PID gets 30%
w_out =  (heading_error * Khp) + (error_sum * Khi) + (heading_rate * Khd);% + offset_error*Kop + (offset_sum * Koi) + (offset_rate * Kod);

% display for testing
fprintf('he: % 2.2f es: % 2.2f hr: % 2.2f p: % 2.2f i: % 2.2f d: % 2.2f oe: % 2.2f os: % 2.2f or: % 2.2f p: % 2.2f i: % 2.2f d: % 2.2f w: % 2.3f dt: % 1.3f\n', heading_error, error_sum,heading_rate,(heading_error * Khp), (error_sum * Khi), (heading_rate * Khd), offset_error, offset_sum, offset_rate, offset_error*Kop,offset_sum * Koi,offset_rate * Kod, w_out, dt);

% close out for next iteration
error_prev = heading_error;
time_prev = time_curr;
offset_prev = offset_error;


end


