function lambda = compute_px2lambda(px,order_num,spectro )
%Calculates the theoretical wavelength of pixel px in the image
% the source in C++ in processing.cpp from the eShel processing module
%  double compute_px2lambda(double px, double k, double dx, INFOSPECTRO &spectro)
% {
%    double gamma = spectro.gamma * PI / 180.0;
%    double alpha = spectro.alpha * PI / 180.0;
%    double beta, beta2;
%    double xc = (double)spectro.imax / 2.0;
% 
%    beta2 = (px - xc - dx) * spectro.pixel / spectro.focale;
%    beta = beta2 + alpha;
%    double lambda = 1.0e7 * cos(gamma) * (sin(alpha) + sin(beta)) / k / spectro.m;
%    return lambda;
% }
%--------------------------------------------
% all lengths are in mm (pixel,focale)
% Here we take dx from the structure spectro
% Micha 18/1/16
gamma_r=spectro.gamma*pi/180;
alpha_r=spectro.alpha*pi/180;
xc=spectro.width/2;
dx=spectro.dx_ref;
beta2=(px - xc - dx) * spectro.pixel / spectro.focale;
beta=beta2+alpha_r;
lambda=1e7*cos(gamma_r)* (sin(alpha_r) + sin(beta)) / order_num / spectro.m;


end

