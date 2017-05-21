function lambda = compute_px2lambda_corr(pos_index,order_num,spectro,order_table )
%Calculates the corrected wavelength of pixel px in the image
% inputs:
% pos_index = index in the array  for which to calc lambda 
% pos_index may ba a vector in which case lambda will be a vector
% order - order number (the real order no. not the index
% spectro - a structure containing the spectrograph data 
% (see % compute_px2lambda function)
% A array of the 3rd order polynom gives the correction to the nominal
% lambda
% i.e. lambda=lambda_nominal+v
% where v=A(order_num,1)+A(order_num,2)*px+A(order_num,3)*px^2+A(order_num,3)*px^3
% Micha 18/1/16
gamma_r=spectro.gamma*pi/180;
alpha_r=spectro.alpha*pi/180;
xc=spectro.width/2;
dx=spectro.dx_ref;
orders=order_table{1};
 min_x=order_table{3}; % min pixel limit of the orders
%  max_x=order_table{4}; % max pixel limit of the orders
 A0=order_table{17};
 A1=order_table{18};
 A2=order_table{19};
 A3=order_table{20};
 ord_indx=find(orders==order_num);
px=min_x(ord_indx)+pos_index;
beta2=(px - xc - dx) * spectro.pixel / spectro.focale;
beta=beta2+alpha_r;
lambda_nom=1e7*cos(gamma_r)* (sin(alpha_r) + sin(beta)) / order_num / spectro.m;

v=A0(ord_indx)+A1(ord_indx)*px+A2(ord_indx)*px.^2+A3(ord_indx)*px.^3;
lambda=lambda_nom+v;
end
