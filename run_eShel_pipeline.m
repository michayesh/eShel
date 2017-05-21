% Run eShel pipeline
% This script  runs the whole eShel pipline.
% it can be run also each step separately.
% Simply run each of the scripts below.
% 
% PPA
eShelPPA_V7_2;
%Converts fit files to mat files
% generates spectra for PPB
% Creates a list of files to process in PPB
% analyses calib filers and generates reports on the calibrations of the
% night.
% This script asks for a night folder to run.
% It can be run on a star folder as well.


%PPB
eShelPPB_V7_2;

%Update orbit data base
update_sys_db_V3;




