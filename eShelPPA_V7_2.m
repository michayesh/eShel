%%  eShel Post Process part A
%========================================================================
%       Proccess eShell Spectra Created by the eShel module in Audela
% The script:
%
% 1. Creates a mat folder to put the output mat files there
% 2. Processes the fit files:
%       3.1 flips the orders to match unicor demands
%       The sequence of orders is flipped so that they go from blue to red.
%       3.2 extracts and calculates observational data
%       3.3 flattens the spectra and clips positive spikes to cliplevel
%       Flattening using Flavien function - clean_norm
%       3.5 calculates signal, total counts and SNR
% 3. saves all the data in a mat file
% 4. Distributes (copies) the mat files  to object folders for the next
% processing stage
% 5. Sends mail with report of the measurements to a list of recepients
%
% The function creats a mat file for every processed fit exposure file
% in the mat folder. (with the same name but .mat extension)
%   The output mat file contains:
%   Keywords - a structure of keywords as extracted from the Audela processed fit file
%   cal - a structure that contains data about the calibration used for the the specific exposure
%   spect - A structure array of the flattenned and clipped spectra for each order.
%   One structure for each order.
%   filename - the file name of the original fit file used to create the
%   mat file
%   obs_data - a structure that contains observation data about the star
%   and specific exposure
%  This script can be run on a star folder (as opposed to a night
%  measurement folder).
% In this case the script runs on fit files in the spectra folder of the
% star. In this mode the mail option is supressed.
% -------------------------------------------------------------------------
%            by Micha
%   v6_3: updated:19 August 2015 matlab R2013a
%   v6_4: updated:3 Sept 2015 matlab R2013a
%   v6_5: updated:9 Sept 2015 matlab R2013a - send mail and clip
%   v6_6: 25 Sept 2015 read master table and reprot mag and airmass
%   v6_7: 3 Oct 2015 - read params from ini file
%   v6_8: 4 oct 2015 - reorganize the script and add the distribute of the fit files
%   v6_9: 9 apr 2016 - incorporate calib analysis
%   V6_10: error catching included
%   V7_0: connection to PPB via file list, removed plots from PPA
%   V7_1: corrected bugs
%
%
%  uses:
%   readeshel,  get_obs_data, read_calib
%    clean_norm, quantfiltdiff quantfilt by Flavien Kiefer
%    ini2struct  by Andriy Nych from matlab central
%    calls: calib_analysisV3_2
%==========================================================================
%
%dbstop if error
clear;
close all; % close all plots
%% Set all environment variables


% mail_recipients = cell(4,1);
% mail_recipients{1}= 'michayesh@gmail.com';
% mail_recipients{2}= 'sahar.shahaf@gmail.com';
% mail_recipients{3}= 'mazeh@post.tau.ac.il';
% mail_recipients{4}= 'stomerzi@gmail.com';

% Set eShel mail definitions:
mail     = 'eshel.tau@gmail.com';
username = 'eshel.tau';
password = 'm.Nefitsa';
port     = '465';
server   = 'smtp.gmail.com';

setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server',server);
setpref('Internet','SMTP_Username',username);
setpref('Internet','SMTP_Password',password);

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', ...
    'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port',port);


%--------------------------------------------------------------------------
comp_name = getenv('COMPUTERNAME');

switch comp_name
    
    case 'ESHEL-RED'
        % eShel_red---------------------------------------------------
        addpath('C:\Users\mizpe\Documents\MATLAB\eShel\eShel_proc\');
        
        % %unicor path
        addpath('c:\Users\mizpe\Documents\MATLAB\unicor'); % eshel_red
        %  %data files path
        data_path='c:\eShel_data';
        addpath(data_path); %eshel_red
        imagepath='C:\Users\mizpe\Documents\audela\images';
        %----------------------------------------------------------------
        
        
    case 'MICHAYESH-DELL' % micha's computer
        % Michas computer----------------------------------------------------------
        % data files path
        addpath('C:\Users\User\Documents\MATLAB\eShel\'); %Micha
        data_path='C:\Users\User\Documents\eShelData_clone\';
        addpath(data_path);% local
        % % unicor path
        addpath('C:\Users\User\Documents\MATLAB\unicor'); % Micha
        imagepath='C:\Users\User\Documents\audela\images';
        
    otherwise
        error('Setup eShel data and  unicor directories.');
end
%--------------------------------------------------------------------------

% read ini file
ini_fn=fullfile(data_path,'eShelpp.ini');
if exist(ini_fn,'file')
params = ini2struct(ini_fn);
else
    error('Could not find eShelpp.ini file');
end




%  get Variables from the param staructure:
target_list_fn=params.PPA.target_list_fn;

send_mail=params.PPA.send_mail; % allows to turn off email send

flatten=params.PPA.flatten;

cal_thr=params.PPA.cal_thr;
% defines threshold to issue warning if cal rms exceeds this value

max_order=params.PPA.max_order;
% take only max orders from red starting from 30

cliplevel=params.PPA.cliplevel; % if cliplevel=0 do not clip

num_rec=length(fieldnames(params.mail_recipients));
mail_recipients=cell(num_rec,1);
for i=1:num_rec
  mail_recipients{i}=  getfield(params.mail_recipients, ['mr' num2str(i)]);
    
end
 mail_recipients=mail_recipients(params.PPA.recepient_filter==1);

if  strcmp(comp_name,'MICHAYESH-DELL')
    send_mail=false; % if it runs on micha's laptop do not send email
end



%% read the master table 


%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% target_list_fn='target_list_test.xls'; % echo it on the display
% target_list_fn='target_list_master.xls'; % echo it on the display 
%
%target_list= dataset('XLSFile',fullfile(data_path,target_list_fn));
target_list= load(target_list_fn);
target_list=target_list.target_list;

if isempty(target_list)
    fprintf('Could not find target master table. \n');
    fprintf('Please verify that the master table exists in the data folder. \n');
    return
end

%% Read and create a list of images in the images folder, initialize structure
% for the spectra and create a log file to echo the command window

cd(imagepath);
%global current_folder_name;
current_folder_name = ...
    uigetdir('Enter night\star folder to process');

cd(current_folder_name);
% list=dir(folder_name);
if exist('processed','dir')
    file_distribute=true; % do the distribution if the folder is a night folder
    work_path=fullfile(current_folder_name,'\processed');
    analyse_calib=true; % do calib analysis only if running on night folder
elseif exist('Spectra','dir') % process the fit files in a star folder 
    work_path=fullfile(current_folder_name,'\Spectra');
    file_distribute=false;
    send_mail=false; 
    analyse_calib=false;% do calib analysis only if running on night folder
else
    work_path=pwd;
    file_distribute=false;
    send_mail=false;
end
cd(work_path);
%*************************************************************************
% initialize spectra structure
field1='filename';file_name=char(zeros(50,1));
% field2='Keywords';Keywords=cell(80,3);
field3='extname';extname=char(zeros(7,1));
field4='deltalam';deltalam=double(0);
field5='lamstart';lamstart=double(0);
field6='lamlen';lamlen=double(0);
field7='data';data=zeros(3000,1);
field8='lam';lam=zeros(3000,1);

spect=struct(field1,file_name,field3,extname,...
    field4,deltalam,field5,lamstart,field6,lamlen,...
    field7,data,field8,lam);
spect=repmat(spect,1,max_order);


% create a log file and echo the screen to this file
% 
g=max(strfind(current_folder_name,'\'));
fnam=current_folder_name(max(g)+1:end);
% 
log_fn=[datestr(now,'yymmddTHHMM') '_'  fnam '_PPA_log.txt'];
% end

diary(fullfile(current_folder_name,log_fn)); % echos creen to a log file
% put in the log the script file name
script_name=mfilename;
fprintf(' %s started \n',script_name);


% find in the work directory the files to process
filter='*.fit';
f_list=dir(fullfile(work_path, '\', filter));
if isempty(f_list)
    error('No fit files to process. Update work directory.');
else
    fprintf('Date:  %s    \n',datestr(now));
    fprintf('flatten= %d    Clip_level= %3.1f   \n',flatten,cliplevel);
    fprintf('Send mail= %d \n',send_mail);
    fprintf('Folder name:  %s \n',work_path);
    fprintf('Found   %d   files to process \n',length(f_list));
end








% Create mat directory under ...\Images\date\ if it does not exist
[mat_status,~,mat_messageid]=mkdir(work_path,'mat');
if ~mat_status
    error('Could not reach or create mat folder');
end



fprintf('%-40s \t %-10s \t %-12s \t %-3s \t %-7s \t %-7s \t %-10s \t %-10s \t %-7s \t %-7s \n',...
    'File name','Obj_name','JD','mag.','Exposure','Airmass','Signal','Total_cnts','snr','calrms');



% Init variables for the exposure data
obs.f_name       =       cell(1,1);
obs.obj_name     =       cell(1,1);
obs.JD           =     	zeros(1,1);
obs.mag          =      zeros(1,1);
obs.exposure     =       zeros(1,1);
obs.airmass      =       zeros(1,1);
obs.max_signal   =       zeros(1,1);
obs.total_counts =       zeros(1,1);
obs.snr          =       zeros(1,1);
obs.cal_rms      =       zeros(1,1);
%
%
% 
%% Process the files

%
for filenum=1:length(f_list) % loop on the exposures (file list)
  
 try   
    
    [rspect0,signal0]=readeshel(f_list(filenum).name);
    %  rspect0- structure array with wavelength calibrated components
    %(those containingthe 'B' in the %extension name) -see details below
    % signal0 -Raw signal components (those containing the 'A' in the extension name)

      
    % read the header section of the fit file
    info=fitsinfo(f_list(filenum).name);
    
    %read calib data from file
    cal=read_pcalib(f_list(filenum).name);
    
    


    
    % max_order was read from the ini file
    rspect=rspect0(1:max_order);
    signal=signal0(1:max_order);
    cal_rms=cal.rms_cal(1:max_order);
    
    % invert the order list blue =1 redest=end
    rspect=flipdim(rspect,2);
    signal=flipdim(signal,2);
    cal_rms=flipdim(cal_rms,1);
    
    % Calculate max signal strength based on the maximun of smoothed raw signals
    ord_signal=zeros(max_order,1);
    
    tot_sig=zeros(max_order,1);
    
    
    for k=1:max_order
        %
        tot_sig(k)  = sum(signal(k).data);
        
        % calc span for smoothing the signal
        span=floor(length(signal(k).data)/10);
        % smooth the signal of order k
        signalvector=smooth(signal(k).data,span);
        % find the median of the smoothed signal for order k
        %new_max_signal=max(signalvector);
        ord_signal(k)=median(signalvector);
    end % loop of  signal orders
    
            
    %% Flatten the spectra and concat the order spectra to one long spectrum
    % Flatten the spectra and clip the spikes above 1
    %         uses Flavien function
    
    %
    
    [nspec,conti]=clean_norm(rspect,5,0.7,'simple-robust');
    %   
    
    
        
    for order=1:max_order
               clear fdat;    
        if cliplevel>0 % if clip level=0 do not clip
            fdat=nspec(order).data;
            fdat(fdat>cliplevel)=cliplevel;
            nspec(order).data=fdat;
        end % end if cliplevel
        
%         % concatenate order spectra to plot a whole continuous spectrum
%         llam=[llam ; nspec(order).lam];
%         lspec=[lspec ; nspec(order).data] ;
        
    end % order loop
     spectrum= concat_orders( nspec );
     lspec=spectrum.spec;
     llam=spectrum.lam;
    % extract SNR values from llam and lspec
    s1=lspec(llam>6670 & llam <6675);
    s2=lspec(llam>6535 & llam <6540);
    snr(1)=mean(s1)/std(s1);
    snr(2)=mean(s2)/std(s2);
    mean_snr=mean(snr);
    
    

    
    
    %% prepare a structure with observation data - calculate airmass
    obs.f_name           =   f_list(filenum).name;
    obs.obj_name        =   get_arr_kwd(info.PrimaryData.Keywords,'OBJNAME');
    obs.JD              =   get_arr_kwd(info.PrimaryData.Keywords,'MJD-OBS')+2400000.5 ;
    obs.exposure      =   get_arr_kwd(info.PrimaryData.Keywords,'EXPOSURE');
    obs.mag         = target_list.mag(strcmp(target_list.name,obs.obj_name ));
    obs.max_signal     =   max(ord_signal);
    obs.total_counts   =   sum(tot_sig);
    obs.snr    =   mean_snr;
    obs.cal_rms        =   mean(cal_rms);
    % find in the target list the correct entry by object name
    RA=char(target_list.RA(strcmp(target_list.name,obs.obj_name )));
    DEC=char(target_list.DEC(strcmp(target_list.name,obs.obj_name )));
    
    if ~isempty(RA) && ~isempty(DEC)
        exp_data=get_obs_data(f_list(filenum).name,false,RA,DEC); 
        obs.airmass =exp_data.AirMass;
%         obs.JD      =exp_data.JD;             
    else
        obs.airmass =   NaN;
%         obs.JD      =   NaN;
        obs.mag     = NaN;
    end
    
    
    % 
    % initialize bad orders vector - all zero means all are good
    obs.bad_orders=zeros(max_order,1);
    % bad order selction is doine in PPB
    
    
    
    %
    %% save the flattened spectrum into a mat variable
    matfn=strrep(f_list(filenum).name,'.fit','.mat');% replace the .fit file extension with .mat
    if exist(fullfile(work_path, 'mat/', matfn),'file')
        delete(fullfile(work_path, 'mat/', matfn)); % deletes existing mat file to prevent file size growth
    end
    savedspec=matfile(fullfile(work_path, 'mat/', matfn),'Writable',true);
    savedspec.filename=f_list(filenum).name;
    savedspec.obs_data=obs;
    savedspec.cal=cal;
    %  puts the Keywords array here
    savedspec.Keywords=rspect(order).Keywords;
    % saves the normalized flattened clipped spectra
    savedspec.spect=nspec(1:max_order);
    
    
%% print exposure data to the screen and log file   
    
%---------------------------------report if cal_rms exceeds the thershold
    if cal_thr>0 && obs.cal_rms >=cal_thr
        calwarn='***cal***';
    else
        calwarn='';
    end
     
fprintf('%-40s \t %-10s \t %-12.3f \t %-3.1f \t %-7.2f \t %-7.2f \t %-10.1f \t %-6.4e \t %-7.2f \t %-7.4f %s \n',...
 f_list(filenum).name,obs.obj_name,obs.JD,obs.mag,obs.exposure,obs.airmass,obs.max_signal,obs.total_counts,obs.snr,obs.cal_rms,calwarn);

catch err
    fprintf('Error in:  %s :  %s \n',f_list(filenum).name,err.message);
    
    continue
 end % try


end % loop for filenum=1:length(f_list) % loop on the exposures (file list)



%% distribute mat files to star folders and save the plots in the night folder

if file_distribute
    
    % Save the plots to the night folder
    
    cd(imagepath);
    
%     saveas(spectra_plot, fullfile(current_folder_name,'spectra.fig'));
%     saveas(cal_plot, fullfile(current_folder_name,'cal_rms.fig'));
    
    
    % Distribute fit  files
    %
    fprintf('****** File Distributor %s *********** \n',datestr(now));
    fit_source_folder=work_path;
    
    if isempty(dir(fit_source_folder))
        fprintf('No processed fit files to distribute \n %s \n Run Audela (?)\n',fit_source_folder);
    else
        fit_list=dir( fullfile(fit_source_folder,'*.fit'));
        num_of_fits=length(fit_list);
        fprintf('Found %d fit files to distribute in %s \n',num_of_fits, fit_source_folder);
        for fit_num=1:num_of_fits
            try
                
                
            % find out the target data folder
            C = textscan(fit_list(fit_num).name, '%*15c %s', 3, 'delimiter', '-');
            obj_name=upper(C{1}); % according to Audela naming convention
            
            fit_target_folder=char(fullfile(data_path,obj_name,'Spectra'));
            % look if the folders exist - if not create it
            if ~isdir(fit_target_folder)
                mkdir(fit_target_folder);
            end
            
            
            fit_source_file=fit_list(fit_num).name;
            
            
            % copy the files
            [copy_status, message]=copyfile(fullfile(fit_source_folder,fit_source_file),fit_target_folder);
            
            if copy_status
                fprintf(' Copied %s --> %s \n',fit_source_file,fit_target_folder);
                
            else
                fprintf(' Failed to copy %s --> %s  %s \n',source_file,mat_target_folder, message);
                
            end % if copy status
            
            
            catch err
                fprintf('------->>> error on %s fit file not transferred.\n',fit_list(fit_num).name);
                fprintf('%s\n',err.message);
            end % try
            
            
        end % : for fit_num=1:num_of_fits
        
    end  %  : if isempty(dir(fit_source_folder))
    
    
        
    % Distribute mat  files
    
    mat_source_folder=fullfile(work_path, 'mat');
    
    
    if isempty(dir(mat_source_folder)) % skip iteration if no "mat" folder exists
        fprintf('No mat files to distribute \n %s \n',mat_source_folder);
    else
        mat_list=dir( fullfile(mat_source_folder,'*.mat'));
        num_of_mats=length(mat_list);
        fprintf('Found %d mat files to distribute in %s \n',num_of_mats, mat_source_folder);
        
        
        
        % for every file in the list :
        %distributethe mat files and create a list fo processed folders for
        %PPB
        ppb_list=cell(num_of_mats,1);
        for mat_num=1:num_of_mats
            
            try
                
                
            % find out the target data folder
            C = textscan(mat_list(mat_num).name, '%*15c %s', 3, 'delimiter', '-');
            obj_name=upper(C{1}); % according to Audela naming convention
            mat_target_folder=char(fullfile(data_path,obj_name,'Spectra\mat'));
            % look if the folders exist - if not create it
            if ~isdir(mat_target_folder)
                mkdir(mat_target_folder);
            end
            mat_source_file=mat_list(mat_num).name;
            
            % copy the files
            [copy_status, message]=copyfile(fullfile(mat_source_folder,mat_source_file),mat_target_folder);
            
            if copy_status
                fprintf(' Copied %s --> %s \n',mat_source_file,mat_target_folder);
                
            else
                fprintf(' Failed to copy %s --> %s  %s \n',source_file,mat_target_folder, message);
                
            end % if copy_status
            
            catch err
                
                fprintf('------->>> error on %s mat file not transferred.\n',mat_list(mat_num).name);
                fprintf('%s\n',err.message);
                
            end % try
            
            ppb_list(mat_num)=obj_name;
        end % for mat_num=1:num_of_mats
        
    end % if isempty(dir(mat_source_folder))

fprintf('****** Distributor finished  %s *********** \n',datestr(now));
    
% Save the current folder list in a mat file

save(fullfile(data_path,'ppb_file_list.mat'),'ppb_list');




end % if file_distribute


% send e-mail with the report

diary off;

subject=['eShel night measurement report  ' datestr(datevec(now),'dd-mmmm-yyyy')];
message=[ mfilename ':  eShel report on measurements in the attached file. ' ];
%send mail with the diary log file as attachment:
if send_mail
    sendmail(mail_recipients , subject ,message,fullfile(current_folder_name,log_fn));
    fprintf('Report mail sent!');

end



fclose('all');
close all;

% call calib analysis
if analyse_calib % do calib analysis only if running on night folder
calib_analysisV3_2(current_folder_name);
end



%-----------------  End of PPA      ---------------------------------------







