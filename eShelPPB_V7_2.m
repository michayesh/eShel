%========================================================================
%       eShel Post Process part B
%------------------------------------------------------------------------
% Process mat files prepared by eShel PP part A
% Before running this script:
% mat files of flattened spectra should be in a star_name\mat folder
% it runs on a list of stars from a target list.
% Two modes of operation:
%   1) differential - only the ones with new data, (based on a list
%   genertated by part A of the pipeline (PPA)
%   2) non differential - runs on all the targets in the list (with run=1)
%  
% Uses the following:
% 1) traget list  -  an xls file with a list of targets and their parameters
%  object_parameters required are:
%       Star name (text i.e 'HR6707')
%       RA hh:mm:ss.s (text)  of the star
%       DEC +-dd:mm:ss.ss (text) of the star
%       run flag  0= skip this star, 1= process this star
%       other paramunieters are optional
% 2) mat files that are products of eShel PP part A
% 3) vhelio mat file in the object directory - if does not exist it will
% not run unicor for the object
%
% Generates:
% 1) Updated mat files with VHELIO correction and other observational
% parameters derived from the RA and DEC of the star
% 2) A plot of all the spectra of the star
% 3)  A plot with the number of measurements and their timing per star
% 4) A signal table = text table with JD, airmass, signal, snr, VHELIO for
% each exposure
% 
% The script calls process_PP_mats function.
% The process_PP_mats function :
%   1)  Updates mat files with VHELIO correction and other observational
%   parameters derived from the RA and DEC of the star
%   2) Generates a plot of all the spectra of the star
%   3) Generates a plot with the number of measurements and their timing per star
%   4) A signal table = text table with JD, airmass, signal, snr, VHELIO for
%   each exposure
% 
%   process_PP_mats calls UNICOR (only for SB1's) .
%   UNICOR outputs an RV data set in the RV folder of the star and calls
%   orbosafla that calculates the solution for the target

%
%   
%
%
%-------------------------------------------------------------------------
%            by Micha
%            matlab R2013a
%            updated: 2 Sep 2015 - automated pipeline
%              updated: 16 Sep 2015 automated e-mail
%            updated 2 Oct 2015 to include Sahar's solver
%            updated 3 Oct 2015 - read params from ini file
%            update  19 Oct 2015 -set priority in target list and attach plots
%            updated 4 Nov 2015 - corrected bug in meridian calc -ver 8.4
%            updated 5 Jan 2016 = removed fig attachments and added prog
%            name to the name of the plots
%  Update: added meridian (meridian transit) calculation for the object list
% ver 6.9 No change in code - micha 10/4/16
% ver 6.10 simplified single object processing
%  ver 7.0 Arrange RV plot report, correct bugs
%  ver 7.2 incorporates functios: process_PP_mats and create_attachments
%   15 July 2016
%
%
%
%
%
%  uses: get_obs_data
% Calls unicor and orbosahar  by Sahar
%==========================================================================
%
% Requires for heliocentric correction:
% Vhelio table for heliocentric v correction of the form
% <objname>Vhelio.mat if not found the pipe line runs but no RV calc.
%========================================================================

%dbstop if error

clear;
close all; % close all plots
fclose('all');
%>>>>>>>>>>>>> E-mail definitions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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



%
% report_attachments=cell(500,1);
%>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


%==========================================================================

%--------------------------------------------------------------------------
%==========================================================================
comp_name = getenv('COMPUTERNAME');

switch comp_name
    
    case 'ESHEL-RED'
        % eShel_red---------------------------------------------------
        addpath('C:\Users\mizpe\Documents\MATLAB\eShel\eShel_proc\');
        % %unicor path
        addpath('c:\Users\mizpe\Documents\MATLAB\unicor'); % eshel_red
        addpath('c:\Users\mizpe\Documents\MATLAB\unicor\DATA'); % autorun_settings.mat location
        %  %data files path
        data_path='C:\eShel_data';%eshel_red
        
        %----------------------------------------------------------------
        
        
        % case 'MICHAEL-DOCK' % micha's computer
    case 'MICHAYESH-DELL' % micha's new computer
        % Michas computer----------------------------------------------------------
        addpath(genpath('C:\Users\User\Documents\MATLAB\eShel\eShel_proc\eShelPipeLine')); %Micha
        % % unicor path
        addpath('C:\Users\User\Documents\MATLAB\unicor'); % Micha
        addpath('C:\Users\User\Documents\MATLAB\unicor\DATA');% autorun_settings.mat location
        % data files path
        data_path='C:\Users\User\Documents\eShelData_clone'; % on micha's computer
        % data_path='d:\eShelData\';
        
        
    otherwise
        error('Setup eShel data and  unicor directories.');
end

% Read ini file and Initialize variables

addpath(data_path);
cd(data_path);
%==========================================================================
% read ini file
ini_fn=fullfile(data_path,'eShelpp.ini');
if exist(ini_fn,'file')
    params = ini2struct(ini_fn);
else
    error('Could not find eShelpp.ini file');
end


% =============================initialize Variables =======================
%  get Variables from the param staructure:
send_mail=params.PPB.send_mail;
% allows to turn off email send

target_list_fn= params.PPB.target_list_fn;

% run_single_system=params.PPB.run_single_system;
% flag- if true run on a single system folder only - next param defines the
% object


%single_obj_name=params.PPB.single_obj_name;


run_differential=params.PPB.run_differential;



%  get mail recipients table
num_rec=length(fieldnames(params.mail_recipients));
mail_recipients=cell(num_rec,1);
for i=1:num_rec
    mail_recipients{i}=  getfield(params.mail_recipients, ['mr' num2str(i)]);
    
end
mail_recipients=mail_recipients(params.PPB.recepient_filter==1);
% do not send mail to filtered out recipients




% Start - read and prepare the target list






%Mizpe Ramon coordinates: E34d45m48s  N30d35m45s
sitelat =0.533998029058098; % radians
sitelon=0.606734625634962; % radians



%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% get current Julian date

 cur_jd=juliandate(now);


% initialize the log file

log_file_name=['eShelPPB_log_' datestr(now,'yyyymmddTHHMM') '.txt'];
% start diary

diary(fullfile(data_path,log_file_name)); % echo the screen to the logfile

%read the target list xls file into a dataset
% target_list= dataset('XLSFile',target_list_fn);
 %target_list= load(target_list_fn,target_list);
target_list= load(target_list_fn);
target_list=target_list.target_list;
% initialize meridian as cell variable
%target_list.meridian=cell(size(target_list,1),1);
target_report_fn=['target_rep_' datestr(now,'yyyymmdd')] ;


% Display diary title
% Dispaly the target list file name
fprintf(' \n \n ************************** START **************************************\n');
fprintf('%s \n Target list file name: %s \n \n',mfilename,target_list_fn);
fprintf('Started on %s  \n Current JD is:  %7.3f \n',datestr(now), cur_jd);
%
%fprintf('Run Unicor flag= %d  \n  Bad order rms cal Thershold= %3.2f \n',...
   % params_PPB.unicor_switch) %, params_PPB.cal_thr_ord);
    
    fprintf('Run Unicor flag= %d  \n' , params.PPB.unicor_switch) ;
fprintf('Exclude_telluric= %d  \n run_differential= %d \n Send mail flag=%d \n',...
    params.PPB.exclude_telluric,params.PPB.run_differential,params.PPB.send_mail);

%fprintf('Run on a single system flag= %d \n \n', run_single_system);





% Check for a list of objects generated by PPA and generate a new target
% filter

if  run_differential &&   exist(fullfile(data_path,'ppb_file_list.mat'),'file')
    load(fullfile(data_path,'ppb_file_list.mat'),'ppb_list');
    
    [~,list2run,~]=intersect(target_list.name,ppb_list);
    
elseif run_differential
    
    error('run_differential=true and noppb_file_list.mat!') ;
    
end % if exist(fullfile(data_path,'ppb_file_list.mat'),'file')



if ~run_differential
    
    list2run=1:size(target_list,1);
    send_mail=false;
    
end %if ~run_differential


% 
ntargets=size(list2run,1);




fprintf('Number of systems to process: %d \n',ntargets);
fprintf('***********************************************************************\n');

%proc_params.unicor_switch=


   target_list  = process_PP_mats(target_list, list2run,params.PPB );
  
  
  

    
    
    %###################################################
  % update meridian data and observability for all targets in target list
  
    for cur_target=1:size(target_list,1)
    meridian_data=meridian_calc(target_list.RA{cur_target},params.PPB.time_zone,params.PPB.night_length , 'Wise');
    
    
    
    target_list.meridian(cur_target)=cellstr(meridian_data.meridian_hour_string);
    target_list.observable(cur_target)=meridian_data.observable;
        
    
    end %t=1:size(target_list,1)
    
    
    report_attachments  = create_attachments( target_list,list2run );
    
  
    

% export the updated target list to a xls file
save(fullfile(data_path,target_list_fn),'target_list');
%export(target_list,'XLSfile',fullfile(data_path, target_list_fn));


% export the updated target list to a xls target_rep file
export(target_list,'XLSfile',fullfile(data_path, target_report_fn));



% add the xls report file to the attachemnet list


new_index=find(cellfun(@isempty, report_attachments),1);
report_attachments{new_index+1}=[fullfile(data_path, target_report_fn) '.xls'];







% send mail containing the results and target report

subject=['eShel night measurement report Part B' datestr(datevec(now),'dd-mmmm-yyyy')];
message=[ mfilename ':  eShel report on measurements in the attached file. ' ];
%send mail with the diary log file as attachment:
if send_mail
    %delete empty cells in recipients array and attachment array
    report_attachments=report_attachments(~cellfun(@isempty,report_attachments));
    mail_recipients=mail_recipients(~cellfun(@isempty,mail_recipients));
    % send mail
    sendmail(mail_recipients , subject ,message,report_attachments);
    fprintf('Report mail sent!\n');
end %if send_mail


fprintf('eShel PPB finished %s',datestr(now));


diary off;







