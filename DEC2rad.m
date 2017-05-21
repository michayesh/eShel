function dec_rad=DEC2rad(DEC)
% converts DEC coordinate given as string to DEC coordinate in radians
% Input: DEC - string of declination coordinate dd:mm:ss.s
% output ra - the angle in radians
% Micha 24-9-13
%==========================================================================
D=sscanf(DEC,'%d:%d:%f');
siman=sign(D(1));siman(siman==0)=1;
dec_rad=siman*(abs(D(1))+D(2)/60+D(3)/3600)*pi/180;
