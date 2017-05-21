function cal=read_pcalib(fn)
% read calib data table from a processed image file of Audela
% eShel module ver. 2.2
orders = fitsread_binary_benny(fn,'BinTable',1);
cal.order=orders{:,1}; 

cal.rms_order =orders{:,15};

cal.rms_cal =orders{:,21};
cal.fwhm =orders{:,22};
cal.disp =orders{:,23}; 
cal.resolution =orders{:,24};
cal.nb_lines =orders{:,25};

