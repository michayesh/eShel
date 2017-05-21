function obs_dat=calc_obs_dat(keywords,p_flag,varargin)
% This function calculates airmass from the object fit keywords 
% and outputs these prameters in a structure obs_dat
%inputs:
%   keywords - keywords cell array as it is extracted by the fitsinfo
%   function
%   p_flag - flag - if true print to the screen the data
% optional inputs:
% RA  as string 'hh:mm:ss.ss'
% DEC as string '+/-dd:mm:ss.ss'
% if these two inputs exist they override the DEC and RA in the fits header
%outputs:
% obs_par-  structure with the data
%                          object_name (string)
%                          JD julian date of exposure start [number]
%                          MeanSidTime - mean sideral time [day fraction]
%                          HorCoo - object azimuth,elevation [radians]
%                          AirMass - airmass at the obseravtion [number]
%           !!!!calculations done for start of exposure -for now!!!
% uses:
% get_arr_kwd
% DEC2rad, RA2rad, lst (eo),...
%....hardie (eo), horiz_coo(eo)
% eo= from Eran Ofek library of matlab functions
% Micha 22-7-15
%=========================================================================
n_args = length(varargin);

obs_dat.object_name= get_arr_kwd(keywords,'OBJNAME');
% get site longitude and convert to radians
sitelong= get_arr_kwd(keywords,'SITELONG');
lon=sscanf(sitelong,'E %2u d %2u m %2u');
site_lon_deg=(lon(1)+lon(2)/60+lon(3)/3600);
site_lon_rad=(lon(1)+lon(2)/60+lon(3)/3600)/180*pi;

% get site latitude and convert to radians
sitelat=get_arr_kwd(keywords,'SITELAT');
lat=sscanf(sitelat,'N %2u d %2u m %2u');
site_lat_rad=(lat(1)+lat(2)/60+lat(3)/3600)/180*pi;
% get observation date and time
obs_date=get_arr_kwd(keywords,'DATE-OBS');

% get JD of observation
MJD= get_arr_kwd(keywords,'MJD-OBS'); % MJD = JD - 2400000.5
obs_dat.MJD=MJD; % for vhelio interpolation
obs_dat.JD=MJD+2400000.5;% MJD = JD - 2400000.5 

% get object RA and convert it to radians
if n_args==0 
RA=get_arr_kwd(keywords,'RA');
else
    RA=varargin{1};
end
ra_rad=RA2rad(RA);


% get object DEC and convert it to radians
if n_args==0 
DEC= get_arr_kwd(keywords,'DEC');
else
    DEC=varargin{2};   
end
dec_rad=DEC2rad(DEC);


% calculate local sideral time of the observation (start of exposure)
%Eran Ofek function - does not give correct LST
% obs_data.MeanSidTime=lst(obs_data.JD,site_lon_rad);% mean sideral time given as fraction of day
% A correct calculation
UTDate=obs_dat.JD-2451545;
GMST = 280.46061837 + 360.98564736629 * UTDate;%Greenwich mean sidereal time
% based on http://www2.arnes.si/~gljsentvid10/sidereal.htm
obs_dat.MeanSidTime=(GMST-fix(GMST/360)*360+site_lon_deg)/180*pi; 
%local mean sidereal time  here in radians

fmst=obs_dat.MeanSidTime/(2*pi); %fraction of a day
LSThr=floor(fmst*24);
LSTmn=floor((fmst-LSThr/24)*1440);
LSTsc=floor((fmst-LSThr/24-LSTmn/1440)*86400);

% calculate horizontal coordinates
obs_dat.HorCoo=horiz_coo([ra_rad dec_rad],obs_dat.JD,[site_lon_rad site_lat_rad],'h'); % Eran Ofek
% convert azimuth and elevation to deg
Az=obs_dat.HorCoo(1)*180/pi; El=obs_dat.HorCoo(2)*180/pi;

obs_dat.AirMass = hardie(pi./2 - obs_dat.HorCoo(:,2)); % Eran Ofek

if p_flag 
    fprintf('Object Name: %s \n',obs_dat.object_name); 
    fprintf('Observation date: %s \n',obs_date);
    fprintf('Observation MJD: %7.3f \n',obs_dat.MJD);
    fprintf('Observation local sideral time %u:%u:%u \n',LSThr,LSTmn,LSTsc);
    fprintf('Object coordinates: RA=%s  DEC=%s / Az=%3.2f El=%3.2f \n',RA,DEC,Az,El);
    fprintf('Observation airmass=%3.2f \n',obs_dat.AirMass);
end
