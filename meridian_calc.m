 function meridian_data=meridian_calc(RA,time_zone, night_length,obs_name)
%----------------------------------------------------------------------------
% Calculated the meridian of an object at  the current date
% 
%----------------------------------------------------------------------------
% Inputs:
% RA - in string format 'HH:MM:SS'
% 
% time zone - for israel = 2 in winter and 3 in summer

% night_length - the length of the night in hours (14 in the winter 8 in summer)

% obs_name - observatory name 'Wise'

%Output
% meridian_data structure
% meridian_data.lmst=local mean sidereal time
% meridian_data.d_meridian=the delta of the meridian from midnight in fraction of a day
% meridian_data.jd_tr= the jd of the meridian
% meridian_data.tr_hr_str = time of meridian in string format 'HH:MM:SS'
% meridian_data.obseravble= 1 if it can be observed tonight =0 - not
% Uses:
% observatory_coo - Eran Ofeq
%
midnight=floor(now+1);
midnight_ut=midnight-time_zone/24; % midnight in UT
jd_midnight=juliandate(datevec(midnight_ut));
% jd_now=juliandate(datevec(now-time_zone/24));

% obj_dat=calc_obj_time(RA,DEC,jd_midnight,p_flag);


ObsCoo=observatory_coo(obs_name);
% site_lon_rad=ObsCoo(1); % in rad
% site_lat_rad=ObsCoo(2); % in rad
site_lon_deg=ObsCoo(1)/pi*180; % in deg

ra_rad=RA2rad(RA);
ra_day=ra_rad/2/pi; % in fraction of day

% dec_rad=DEC2rad(DEC);


% A correct calculation
UTDate=jd_midnight-2451545;
GMST = 280.46061837 + 360.98564736629 * UTDate;%Greenwich mean sidereal time
% based on http://www2.arnes.si/~gljsentvid10/sidereal.htm

meridian_data.lmst  =(GMST-fix(GMST/360)*360+site_lon_deg)/360; %local mean sidereal in fraction of a day

delta   =(ra_day-meridian_data.lmst); % the delta of the meridian from midnight in fraction of a day

meridian_data.jd_tr = jd_midnight+(ra_day-meridian_data.lmst); % the jd of the meridian

meridian_data.meridian_hour_string=datestr(midnight+delta,'HH:MM:SS');

meridian_data.d_meridian=delta;


%  delta=merid_data.d_meridian;
% abs(delta-round(delta)) is the distance from the nearest midnight
meridian_data.observable=(abs(delta-round(delta)) <= night_length/48);
    
%     if delta <= 0 && delta > -0.5
%         meridian_data.observable = (abs(delta)<= night_length/48);
%     elseif delta <= -0.5 && delta > -1
%         meridian_data.observable = (abs(1+delta) <= night_length/48);
%     else
%         meridian_data.observable = (abs(delta)<= night_length/48);
%     end
