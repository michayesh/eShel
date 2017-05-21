function ra_rad=RA2rad(RA)
% converts RA coordinate given as string to RA coordinate in radians
% Input: RA - string of RA coordinate hh:mm:ss.s
% output ra - the anglr in radians
% Micha 24-9-13
%==========================================================================
H=sscanf(RA,'%d:%d:%f');
ra_rad=(H(1)/24+H(2)/1440+H(3)/86400)*2*pi;
