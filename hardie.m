function Xz=hardie(x,c_z)
%--------------------------------------------------------------------
% hardie function      calculate airmass using hardie formula.
% Input  : - Matrix in which one of the columns is zenith distance
%            in radians.
%          - The zenith distance column.
% Output : - Air mass.
% Tested : Matlab 4.2
%     By : Eran O. Ofek           January 1994
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html
%--------------------------------------------------------------------
RAD = 180./pi;
if nargin==1,
   c_z = 1;
elseif nargin==2,
   % do nothing
else
   error('eran:hardie','Illegal number of input arguments');
end

secz=1./cos(x(:,c_z));
Xz = secz - 0.0018167.*(secz - 1) - 0.002875.*(secz - 1).*(secz - 1) - 0.0008083.*(secz - 1).*(secz - 1).*(secz - 1);


I = find(x(:,c_z)>87./RAD);
Xz(I) = NaN; % put NaN for zenith angles >87 deg
