function [total_signal,signal] = get_eshel_signal( file_name )
% Extracts the signal from a processed eshel object file
% generates signal(norders) - array fo structures with
% signal(order).lam, signal(order).data
info=fitsinfo(file_name);
% Read the calib table as well
 order_table=fitsread_binary_benny(file_name,'BinTable',1);
 

 %rms_cal=order_table{21};
orders=order_table{1};
 n_orders=size(orders,1);
 
spectro.alpha=get_arr_kwd(info.BinaryTable.Keywords,'ALPHA');
spectro.beta=get_arr_kwd(info.BinaryTable.Keywords,'BETA');
spectro.gamma=get_arr_kwd(info.BinaryTable.Keywords,'GAMMA');
spectro.focale=get_arr_kwd(info.BinaryTable.Keywords,'FOCLEN');
spectro.m=get_arr_kwd(info.BinaryTable.Keywords,'M');
spectro.pixel=get_arr_kwd(info.BinaryTable.Keywords,'PIXEL');
spectro.dx_ref=get_arr_kwd(info.BinaryTable.Keywords,'DX_REF');
spectro.ref_num=get_arr_kwd(info.BinaryTable.Keywords,'REF_NUM'); % order of the ref line
spectro.ref_x=get_arr_kwd(info.BinaryTable.Keywords,'REF_X');
spectro.ref_y=get_arr_kwd(info.BinaryTable.Keywords,'REF_Y');
spectro.ref_l=get_arr_kwd(info.BinaryTable.Keywords,'REF_L'); % wavelength of ref line
spectro.width=get_arr_kwd(info.BinaryTable.Keywords,'WIDTH'); % imax in the eshel source code
spectro.height=get_arr_kwd(info.BinaryTable.Keywords,'HEIGHT');
spectro.orders=order_table{1};
[~,sig]=readeshel(file_name);

total_signal=0;
for order=1:n_orders
order_num=orders(order);    
pos_index=1:size(sig(order).data);
% compute_px2lambda translated from the eShel module source code
lam=compute_px2lambda_corr(pos_index,order_num,spectro,order_table );
lam=lam(:); %column vector
data=sig(order).data;
total_signal=total_signal+trapz(lam,data);
signal(order).lam=lam;
signal(order).data=data;


end %for order=1:n_orders


end

