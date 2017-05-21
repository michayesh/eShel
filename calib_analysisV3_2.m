function calib_analysisV3_2(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calibration analysis 
% Matlab 2013a 
% varargin
%  input#1 = night folder name= the folder that conatains the
% calibration files to be analysed
% if no input #1 - the function will prompt for the folder to process
%  and for temperature log file to load
%
% Reads from a folder with calibration files the calibration data
%
% extracts shifts in line positions
% Correlates with temperature logs - if exist
% 
% Uses the functions:
% read_calib_detailed function
% get_fit_kwd
%
% v 3.0 added plot of yshift vs xshift
% V 3.1 Saves data for global analysis 10/5/16
% V 3.2 work as a function to be integrated in the pipeline
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear;
C=299792.458; % in km/s
% close all;


%if exist('current_folder_name','dir')
if nargin>0
    % operates within PPA
    calib_path=varargin{1};
    logfn=0; % skip reading tem log file name
else
    % operated manually
    calib_path=uigetdir('C:\Users\mizpe\Documents\audela\images',...
        'Choose night folder with calibration files to analyse');
    [logfn,logpath]=uigetfile('*.mat','Enter temperaturelog file name:');
end
    

l=strfind(calib_path,'images\');
ll=l(end); % look for the last occurance
folder_date=calib_path(ll+7:ll+14);

calib_path=fullfile(calib_path,'reference');
file_list=dir(fullfile(calib_path,'*CALIB*.fit'));
if isempty(file_list)
    fprintf('No calib files found.');
    return
else
    fprintf('CALIB Analysis \n');
    fprintf('Date: %s Found %d calib files \n',folder_date, size(file_list,1));
end

%%
% option to load temperature logs only in manual operation

%[logfn,logpath]=uigetfile('*.mat','Load temperature log file that covers the calib time');
% logpath='C:\Users\mizpe\Documents\MATLAB\eShel\calib_analysis';
% logfn='20160323_10425630_2016templog.mat';
% logfn='temp_2016.mat';
if logfn==0
tlog_exists=false;

elseif exist(fullfile(logpath,logfn),'file')
load(fullfile(logpath,logfn),'temp');
     tlog_exists=true;
else
    tlog_exists=false;
end % if logfn=0

    




nfiles=size(file_list,1);
%order=cell(nfiles,25);
%lgap=cell(nfiles,7);
%orderlist=[1 5 10 15 20]; % only first 4 are ploted in the multiplot figure
orderlist=[5 10 15 20]; % only first 4 are ploted in the multiplot figure
%wv_list=[7481.355 6403.013 5597.476 4972.160 4481.810];
%wv_list=[6403.013 5597.476 4972.160 4481.810];
wv_list=[4592.666 4686.195 4789.387 4889.042 ...
    5002.097 5115.045 5231.160 5360.15 5495.874 ...
    5753.026 5928.813 6088.030 6248.405 6431.555 ...
    6632.084 6827.249 7030.251];
norders=size(orderlist,2);
mjd0=zeros(nfiles,1);
ton=zeros(nfiles,1);
lamdif=zeros(nfiles,size(wv_list,2));
lamobs=zeros(nfiles,size(wv_list,2));
% caldata=zeros(nfiles,25,norders);
lgap_ok=cell(nfiles,1);
for f=1:nfiles
    fn=file_list(f).name;
    [cal,lgap]=read_calib_detailed(fullfile(calib_path,fn));
    % mjd0 is the exposure mjd changes in midnight
    mjd0(f)=get_fit_kwd(fullfile(calib_path,fn),'MJD-OBS'); 
   
    ton(f)=mjd0(f)-0.5-fix(mjd0(f)-0.5); % time in the night 0= noon
    lgap_ok{f}=lgap(lgap.valid==1,:); % only those which were not rejected by the algorithm
    caldata.order(f,:)=cal.order(orderlist);
    caldata.min_x(f,:)=cal.min_x(orderlist);
    caldata.max_x(f,:)=cal.max_x(orderlist);
    caldata.A0(f,:)=cal.A0(orderlist);
    caldata.A1(f,:)=cal.A1(orderlist);
    caldata.A2(f,:)=cal.A2(orderlist);
    caldata.A3(f,:)=cal.A3(orderlist);
    caldata.rms_cal(f,:)=cal.rms_cal(orderlist);
    caldata.fwhm(f,:)=cal.fwhm(orderlist);
    caldata.disp(f,:)=cal.disp(orderlist);
    caldata.resolution(f,:)=cal.resolution(orderlist);
    rms_cal(f,:)=cal.rms_cal;
    % collect lanbda_dif for specific wavelengths (near center of order
   for w=1:size(wv_list,2)
       lamdif(f,w)=lgap.lam_dif(lgap.lam_obs==wv_list(w));
       lamobs(f,w)=lgap.lam_obs(lgap.lam_obs==wv_list(w));
       lamposx(f,w)=lgap.lamposx(lgap.lam_obs==wv_list(w));
       lamposy(f,w)=lgap.lamposy(lgap.lam_obs==wv_list(w));
       cur_order=lgap.order(lgap.lam_obs==wv_list(w));
       disper(f,w)=cal.disp(cal.order==cur_order);
   end
   fprintf(' %d',f);
end %for f=1:nfiles

 rmjd=mjd0-mjd0(1); % relative mjd to the first 

% plot the correction for different orders for a specific measurement
cor=cell(nfiles,norders);
fprintf(' \n meas:');
for meas=1:nfiles

for ord=1:norders
    
x=caldata.min_x(meas,ord):caldata.max_x(meas,ord);
% the correction is calculated relative to min x
x=x-caldata.min_x(meas,ord);
x2=x.*x;
x3=x2.*x;

cor{meas,ord}=caldata.A3(meas,ord)*x3 + caldata.A2(meas,ord)*x2+caldata.A1(meas,ord)*x+caldata.A0(meas,ord);
fprintf('.');
end %for ord=1:norders
end %for meas=1:nfiles

% if temperature data exists prepare T data by interpolating on the tem log

if tlog_exists
%  mjd1=interp1(temp.mjd,mjd0); 
 T1=interp1(temp.mjd,temp.T1,mjd0); 
 T2=interp1(temp.mjd,temp.T2,mjd0); 
 T3=interp1(temp.mjd,temp.T3,mjd0); 
 T4=interp1(temp.mjd,temp.T4,mjd0); 
 T=[T1 T2 T3 T4];  
 Tav=mean(T,2);% calc the mean values of each row
 %T=[T1 T2 T3 T4];
 Tt=T(:);
 missing_temp=any(isnan(Tt));
 if missing_temp
     fprintf('No temperatures for this date!\n');
 end % missinng_temp

end %tlog_exists

% Calculate RV drift
xshift=lamposx- repmat(lamposx(1,:),size(lamposy,1),1);
lamshift= xshift.*disper;
lam=repmat(wv_list,nfiles,1);
dv=lamshift./lam*C;
% save(fullfile(calib_path,[folder_date '_dv_T.mat']),'wv_list','Tav','dv');
%% Generate the plots
figure1=figure;
annotation(figure1,'textbox',...
    [0.4 0.99 0.2 0],...
    'String',{['Calibration Corrections: ' folder_date]},...
    'HorizontalAlignment','center',...
    'FontSize',14,...
    'FontWeight','bold',...
    'FitBoxToText','on',...
    'LineStyle','none');
% plot order 1
ax1=subplot(2,2,1,'Parent',figure1);

order=1;
ordernum=caldata.order(1,order);
plotdata1=cell2mat(cor(:,order))';

p1=caldata.min_x(meas,order):caldata.max_x(meas,order);
plot(ax1,p1,plotdata1);
title(ax1,['Order=' num2str(ordernum)],'FontSize',12);
%ylim(ax1,[0 2]);
xlim(ax1,[0 2184]);
ylabel(ax1,'\Delta \lambda [A]','FontSize',12);
xlabel(ax1,'Pixel','FontSize',12);
grid on;


% plot order 2
ax2=subplot(2,2,2,'Parent',figure1);

order=2;
ordernum=caldata.order(1,order);
plotdata2=cell2mat(cor(:,order))';

p2=caldata.min_x(meas,order):caldata.max_x(meas,order);
plot(ax2,p2,plotdata2);
title(ax2,['Order=' num2str(ordernum)],'FontSize',12);
%ylim(ax2,[0 2]);
xlim(ax2,[0 2184]);
ylabel(ax2,'\Delta \lambda [A]','FontSize',12);
xlabel(ax2,'Pixel','FontSize',12);
grid on;

% plot order 3
ax3=subplot(2,2,3,'Parent',figure1);

order=3;
ordernum=caldata.order(1,order);
plotdata3=cell2mat(cor(:,order))';

p3=caldata.min_x(meas,order):caldata.max_x(meas,order);
plot(ax3,p3,plotdata3);
title(ax3,['Order=' num2str(ordernum)],'FontSize',12);
%ylim(ax3,[0 2]);
xlim(ax3,[0 2184]);
ylabel(ax3,'\Delta \lambda [A]','FontSize',12);
xlabel(ax3,'Pixel','FontSize',12);
grid on;

% plot order 4
ax4=subplot(2,2,4,'Parent',figure1);

order=4;
ordernum=caldata.order(1,order);
plotdata4=cell2mat(cor(:,order))';

p4=caldata.min_x(meas,order):caldata.max_x(meas,order);
plot(ax4,p4,plotdata4);
title(ax4,['Order=' num2str(ordernum)],'FontSize',12);
%ylim(ax4,[0 2]);
xlim(ax4,[0 2184]);
ylabel(ax4,'\Delta \lambda [A]','FontSize',12);
xlabel(ax4,'Pixel','FontSize',12);
grid on;
saveas(figure1,fullfile(calib_path,[folder_date '_pol.fig']));
% figure2 = figure;
% laxes=axes('Parent',figure2);
% plot(laxes,ton,caldata.A0);
% xlabel(laxes,'Time from noon');
% % ylabel(laxes,'\lambda_{diff} [A]');
% ylabel(laxes,'A0 [A]');
% xlim(laxes,[0. 1]);

figure2 = figure;

laxes=subplot(2,2,1,'Parent',figure2);

A0_init=repmat(caldata.A0(1,:),nfiles,1);
A0_change=(caldata.A0-A0_init)./A0_init;
A1_init=repmat(caldata.A1(1,:),nfiles,1);
A1_change=(caldata.A1-A1_init)./A1_init;
A2_init=repmat(caldata.A2(1,:),nfiles,1);
A2_change=(caldata.A2-A2_init)./A2_init;
A3_init=repmat(caldata.A3(1,:),nfiles,1);
A3_change=(caldata.A1-A3_init)./A3_init;




%poldata=[A0_change A1_change A2_change A3_change];
% poldata=[A0_change A1_change A2_change];
poldata=caldata.A0;
% pd=plot(laxes,mjd0,poldata,'.');
pd=plot(laxes,rmjd*24,poldata);
%xlabel(laxes,'Time from noon');
grid on;
% xlabel(laxes,'MJD','FontSize',12);
xlabel(laxes,'Time [hr]','FontSize',12);
title(laxes,['A0 Variations: ' folder_date],'FontSize',14); 
% ylabel(laxes,'\lambda_{diff} [A]');
ylabel(laxes,'A0 [A]','FontSize',12);
% xlim(laxes,[0. 1]);

% figure3=figure;
rmsaxes=subplot(2,2,2,'Parent',figure2);
% plot(rmsaxes,rmjd*24,caldata.rms_cal,'.');
plot(rmsaxes,rmjd*24,caldata.rms_cal);
grid on;
title(rmsaxes,'Calibration RMS Variations','FontSize',14);
ylabel(rmsaxes,'RMS Cal','FontSize',12);
%xlabel(rmsaxes,'MJD','FontSize',12);
xlabel(rmsaxes,'Time [hr]','FontSize',12);


%figure4=figure;
posxaxes=subplot(2,2,3,'Parent',figure2);
%plot(posxaxes,mjd,lamposx,'.');
plot(posxaxes,rmjd*24,lamposx- repmat(lamposx(1,:),size(lamposy,1),1));
grid on;
ylabel(posxaxes,'LambdaPos x','FontSize',12);
% xlabel(posxaxes,'MJD','FontSize',12);
xlabel(posxaxes,'Time [hr]','FontSize',12);

title(posxaxes,'Lambda X position Change','FontSize',14);

%figure5=figure;
posyaxes=subplot(2,2,4,'Parent',figure2);

plot(posyaxes,rmjd*24,lamposy- repmat(lamposy(1,:),size(lamposy,1),1));
grid on;
ylabel(posyaxes,'LambdaPos y','FontSize',12);
% xlabel(posyaxes,'MJD','FontSize',12);
xlabel(posyaxes,'Time [hr]','FontSize',12);
title(posyaxes,'Lambda Y position Change','FontSize',14);

saveas(figure2,fullfile(calib_path,[folder_date '_var.fig']));
% plot position changes in 2D y vs x

figureposxy=figure;
axesposxy=axes('Parent',figureposxy);
 hold on;
 for i=1:size(wv_list,2)
%      plot(axesposxy,lamposx(:,i)-lamposx(1,i),...
%          lamposy(:,i)-lamposy(1,i),'Color',[rand(1) rand(1) rand(1)]);
plot(axesposxy,lamposx(:,i)-lamposx(1,i),...
          lamposy(:,i)-lamposy(1,i),'Marker','o','LineStyle','none',...
          'MarkerFaceColor',[rand(1) rand(1) rand(1)]);
 end
grid on;
xlim([-1 1]);
ylim([-1 1]);
xlabel('Xshift [pix]');
ylabel('Yshift [pix]');
title(axesposxy,['Y vs. X Shifts: ' folder_date],'FontSize',14); 
  saveas(figureposxy,fullfile(calib_path,[folder_date '_posxy.fig']));     

  
 % plot RV hifts vs time in the night
rvdrift_fig=figure;
rv_drift_axes=axes('Parent',rvdrift_fig);
plot(rv_drift_axes,rmjd*24,dv);
grid on;
xlabel('Time [hr]','FontSize',12);
ylabel('RV Shift [km/s]','FontSize',12);
title(['RV Shift: ' folder_date],'FontSize',16); 
   saveas(rvdrift_fig,fullfile(calib_path,[folder_date '_rvdrift.fig']));    
  
% temperature log dependent


if tlog_exists && ~missing_temp
corfig=figure; % plot correlation to temperatures

cortempaxes=subplot(2,1,1,'Parent',corfig);

plot(cortempaxes,rmjd*24,T)
grid on;
xlabel('Time [hr]','FontSize',12);
ylabel('Temperature [C]','FontSize',12);
title('eShel Temperature','FontSize',16);

corposaxes=subplot(2,1,2,'Parent',corfig);


plot(corposaxes,rmjd*24,dv);
grid on;
xlabel('Time [hr]','FontSize',12);
ylabel('RV Shift [km/s]','FontSize',12);
title(['RV Shift: ' folder_date],'FontSize',16);
linkaxes([cortempaxes corposaxes],'x');
saveas(corfig,fullfile(calib_path,[folder_date '_cor.fig']));

dvtempfig=figure;
temposaxes=axes('Parent',dvtempfig);
plot(temposaxes,Tav,dv,'Marker','.');
 grid on;
xlabel('Temperature [C]','FontSize',12);
xlim([min(Tav)-1 min(Tav)+5]); % span of 6 deg
ylabel('RV Shift [km/s]','FontSize',12);
title(['RV Shift vs Temperature: ' folder_date],'FontSize',16);


saveas(dvtempfig,fullfile(calib_path,[folder_date '_dvtemp.fig']));
end % if tlog_exists

%% Plot fit quality
% Choose order
% ord_num=1;
%  meas=1;
% cur_order=caldata.order(1,ord_num);
% lgap_meas=lgap_ok{meas};
% lgap_curorder=lgap_meas(lgap_meas.order==cur_order,:);
figure3=figure;
axes5=axes('Parent',figure3);
grid on;
hold on;
for meas=1:nfiles
    plcol=[rand(1) rand(1) rand(1)];
plot(axes5, lgap_ok{meas}.lam_obs,lgap_ok{meas}.lam_dif,'.','MarkerFaceColor',plcol,'MarkerEdgeColor',plcol);
end;
% Create xlabel
xlabel('\lambda [A]','FontWeight','demi','FontSize',14);

% Create ylabel
ylabel('\lambda_{diff} [A]','FontWeight','demi','FontSize',14);

% Create title
title(['Fit Error for: ' folder_date],'FontSize',16);
saveas(figure3,fullfile(calib_path,[folder_date '_fit.fig']));
%  plot(cor{meas, ord_num});
% plot RMS cal 

figure4=figure;

axes6=axes('Parent',figure4);

rms_plot_data=rms_cal';
x_orders=30:50;
plot(axes6,x_orders,rms_plot_data);
grid on;
xlabel('Order #','FontSize',12);
ylabel('RMS_CAL [A]','FontSize',12);
title(['RMS CAL for: ' folder_date],'FontSize',16);
saveas(figure4,fullfile(calib_path,[folder_date '_rms.fig']));

if tlog_exists
 figure5=figure;
  ax7=subplot(2,1,1);
  plot(ax7,rmjd*24,Tav);
  xlabel('Time [hr]');
  ylabel('Temperature [C]');
  title(folder_date);
  grid on;
  ax8=subplot(2,1,2);
   plot(ax8,rmjd*24,dv);
   xlabel('Time [hr]');
  ylabel('RV Shift [km/s]');
  grid on;
  linkaxes([ax7 ax8],'x');

  saveas(figure5,fullfile(calib_path,[folder_date '_dv_Tav.fig']));
end %if tlog_exists
 
save(fullfile(calib_path,[folder_date '_calib_ana.mat']));



