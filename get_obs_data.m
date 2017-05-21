function obs_data=get_obs_data(object_fn,p_flag,varargin)
% This function extracts from object fits file information about the
% obseravtion parameters and calculates airmass
%inputs:
%   object_fn - object file name (processed fits file)
%   p_flag - flag - if true print to the screen the data
% optional inputs:
% RA  as string 'hh:mm:ss.ss'
% DEC as string '+/-dd:mm:ss.ss'
% if these two inputs exist they override the DEC and RA in the fits header
%outputs:
% obs_data-  structure with the data
%                          object_name (string)
%                          JD julian date of exposure start [number]
%                          MeanSidTime - mean sideral time [day fraction]
%                          HorCoo - object azimuth,elevation [radians]
%                          AirMass - airmass at the obseravtion [number]
%           !!!!calculations done for start of exposure -for now!!!
% uses: 
%get_fit_kwd, DEC2rad, RA2rad, lst (eo),...
%....hardie (eo), horiz_coo(eo)
% eo= eran ofek
% Micha 2-4-14
%=========================================================================
n_args = length(varargin);
%object_fn='20130620-175758-HD88230-1x600si.fit';
obs_data.object_name= get_fit_kwd(object_fn,'OBJNAME');

% get site longitude and convert to radians
sitelong= get_fit_kwd(object_fn,'SITELONG');
lon=sscanf(sitelong,'E %2u d %2u m %2u');
site_lon_deg=(lon(1)+lon(2)/60+lon(3)/3600);
site_lon_rad=(lon(1)+lon(2)/60+lon(3)/3600)/180*pi;

% get site latitude and convert to radians
sitelat=get_fit_kwd(object_fn,'SITELAT');
lat=sscanf(sitelat,'N %2u d %2u m %2u');
site_lat_rad=(lat(1)+lat(2)/60+lat(3)/3600)/180*pi;
% get observation date and time
obs_date=get_fit_kwd(object_fn,'DATE-OBS');

% get JD of observation
MJD= get_fit_kwd(object_fn,'MJD-OBS'); % MJD = JD - 2400000.5
obs_data.MJD=MJD; % for vhelio interpolation
obs_data.JD=MJD+2400000.5;% MJD = JD - 2400000.5 

% get object RA and convert it to radians
if n_args==0 
RA=get_fit_kwd(object_fn,'RA');
else
    RA=varargin{1};
end
ra_rad=RA2rad(RA);


% get object DEC and convert it to radians
if n_args==0 
DEC= get_fit_kwd(object_fn,'DEC');
else
    DEC=varargin{2};   
end
dec_rad=DEC2rad(DEC);


% calculate local sideral time of the observation (start of exposure)
%Eran Ofek function - does not give correct LST
% obs_data.MeanSidTime=lst(obs_data.JD,site_lon_rad);% mean sideral time given as fraction of day
% A correct calculation
UTDate=obs_data.JD-2451545;
GMST = 280.46061837 + 360.98564736629 * UTDate;%Greenwich mean sidereal time
% based on http://www2.arnes.si/~gljsentvid10/sidereal.htm
obs_data.MeanSidTime=(GMST-fix(GMST/360)*360+site_lon_deg)/180*pi; 
%local mean sidereal time  here in radians

fmst=obs_data.MeanSidTime/(2*pi); %fraction of a day
LSThr=floor(fmst*24);
LSTmn=floor((fmst-LSThr/24)*1440);
LSTsc=floor((fmst-LSThr/24-LSTmn/1440)*86400);

% calculate horizontal coordinates
obs_data.HorCoo=horiz_coo([ra_rad dec_rad],obs_data.JD,[site_lon_rad site_lat_rad],'h'); % Eran Ofek
% convert azimuth and elevation to deg
Az=obs_data.HorCoo(1)*180/pi; El=obs_data.HorCoo(2)*180/pi;

obs_data.AirMass = hardie(pi./2 - obs_data.HorCoo(:,2)); % Eran Ofek

if p_flag 
    fprintf('Object Name: %s \n',obs_data.object_name); 
    fprintf('Observation date: %s \n',obs_date);
    fprintf('Observation MJD: %7.3f \n',obs_data.MJD);
    fprintf('Observation local sideral time %u:%u:%u \n',LSThr,LSTmn,LSTsc);
    fprintf('Object coordinates: RA=%s  DEC=%s / Az=%3.2f El=%3.2f \n',RA,DEC,Az,El);
    fprintf('Observation airmass=%3.2f \n',obs_data.AirMass);
end
