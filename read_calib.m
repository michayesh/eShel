function [cal, lgap]=read_calib(fn)
% read calib data tables from a calibration file of Audela
% eShel module ver. 2.2
orders = fitsread_binary_benny(fn,'BinTable',1);
linegap = fitsread_binary_benny(fn,'BinTable',2);
cal.order=orders{:,1}; 
% cal.flag=orders{:,2}; 
% cal.min_x =orders{:,3};
% cal.max_x =orders{:,4};
% cal.P0 =orders{:,5};
% cal.P1 =orders{:,6}; 
% cal.P2 =orders{:,7};
% cal.P3 =orders{:,8};
% cal.P4 =orders{:,9};
% cal.P5 =orders{:,10};
% cal.yc =orders{:,11};
% cal.wide_y =orders{:,12};
% cal.wide_x =orders{:,13};
% cal.slant =orders{:,14};
cal.rms_order =orders{:,15};
% cal.central =orders{:,16};
% cal.A0 =orders{:,17};
% cal.A1 =orders{:,18};
% cal.A2 =orders{:,19};
% cal.A3 =orders{:,20}; 
cal.rms_cal =orders{:,21};
cal.fwhm =orders{:,22};
cal.disp =orders{:,23}; 
cal.resolution =orders{:,24};
cal.nb_lines =orders{:,25};
lgap.order=linegap{:,1};
lgap.lam_obs=linegap{:,2};
lgap.lam_calc=linegap{:,3};
lgap.lam_dif=linegap{:,4};
% lgap.lamposx=linegap{:,5};
% lgap.lamposy=linegap{:,6};
% lgap.valid=linegap{:,7};



