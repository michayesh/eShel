function [ target_list ] = process_PP_mats(target_list, targets2run ,proc_params)
%Processes mat file as part of  PPB
% 1. plots the spectra and saves in a figure
% 2. plots meas report and saves the plot
% 3. plots cal RMS and saves the plot
% 4. calculates Vhelio by interpolation on vhelioXXXX.mat
% 5. Updates target list fields
%  Opertates in the directory of tha start folders = data_path
% inputs:
%    target_list - a list of targets based on the master target list format
%   targets2run - a vector of target indices in target_list to process
%    proc_params:
% proc_params.exclude_telluric
% proc_params.object_folder
% proc_params.unicor_switch
%

% output: target_list - updated
data_path=pwd;

targets2run=targets2run(:)'; % row vector needed for loop
for cur_target= targets2run 
   
    obj_folder=target_list.name(cur_target);
    
    %
    obj_path=fullfile(data_path,char(obj_folder));
    mat_path=fullfile(data_path,char(obj_folder), '\Spectra\mat');
    
    obj_name    = target_list.name{cur_target};
    RA          = target_list.RA{cur_target};
    DEC         = target_list.DEC{cur_target};
    mag         = target_list.mag(cur_target);
    period      = target_list.period(cur_target);
    SBtype      = target_list.SBtype(cur_target);
    obj_data.name=obj_name;
    obj_data.prog=char(target_list.prog(cur_target));
    %signal_fn=[obj_name '_'  target_list.prog{cur_target} '_signals.txt'];
    
    fprintf('\n \n Date:  %s    \n',datestr(now));
    fprintf(...
        'Object: %15s \t RA= %12s \t DEC= %12s \n m_v= %4.2f \t Period= %7.2f \n ',...
        obj_name,RA,DEC,mag,period);
    
   
    
    % look for vhelio file
    vhelio_fn=[obj_name 'Vhelio.mat'];
        
    if exist(fullfile(data_path,char(obj_folder),vhelio_fn),'file')
        do_helio=true;
        
    else
        fprintf('\n **************No vhelio file found for this object!******** \n\n');
        do_helio=false;
        %do not insert vhelio into the mat files Keyword array
    end
    
    matlist= dir(fullfile(mat_path,'*.mat'));
    
    if isempty(matlist)
        fprintf('\n ---------------No mat files to process.------------- \n\n');
        target_list.nmeas=0;
        target_list.last=999;
        return
    else
        nmeas=length(matlist);
        fprintf('Found   %d  mat files to process. \n',nmeas);
        
    end
    
    % print a header to the table
    
    
    fprintf('%-40s \t %-12s \t %-7s \t %-7s \t %-7s \t %-10s \t %-10s \t %-7s \t %-7s \n',...
        'File name','HJD','Rphase','Airmass','Exposure','Signal','Total_cnts','snr','calrms');
    
    
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % Here processing starts
    %++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    
    
    
    meas_jd=[]; % forget the previous vector
    clear('meas_spectra','meas_calib');
    
    
    
    % start the loop on the mat
    for meas_num=1:nmeas
        
        try  % error of non existence of cal structure in the mat file
            
            
            load( fullfile(mat_path,matlist(meas_num).name));
            % loads:
            % spect
            % cal
            % obs_data
            % Keywords
            % mat_file_name
            num_orders=size(spect,2);
            
            %Concatenates orders to a single spectrum _ clear them at the
            %beginning
            meas_spectra(meas_num)= concat_orders( spect );
            meas_calib(meas_num)=cal;
            %obj_data.name=obj_name;
            %obj_data.prog=target_list.prog{cur_target};
            
            
           %======================plot spectra ===================================
            
            spec_fig = plot_spectra(meas_spectra,obj_data);
            
          %======================plot cal rms ===================================
            %
            %             plot(axes2, meas_calib(meas_num).order,meas_calib(meas_num).rms_cal,'color',[rand rand rand]);
            
        catch err
            message=[matlist(meas_num).name ': ' err.message '\n Try running PPA on the folder.\n'];
            error('PPB:mat_file_error',message);
            
        end %try: error of non existence of cal structure in the mat file
        
        %======calc airmass and MJD from the fit keywords      ===================
        % Get target data from the list record
        obs_data.obj_name    = obj_name;
        obs_data.RA          = RA;
        obs_data.DEC         = DEC;
        obs_data.mag         = mag;
        obs_data.period      = period;
        obs_data.SBtype      = SBtype;
        
        
        
        
        % get observational parameters from KWDs and calc some
        kwd_dat=calc_obs_dat(Keywords,false,obs_data.RA,obs_data.DEC);
        % copy the values to the obs_data structure loaded from the mat file
        
        
        obs_data.airmass=kwd_dat.AirMass;
        obs_data.JD=kwd_dat.JD;
        obs_data.MJD=kwd_dat.MJD;
        obs_data.HorCoo=kwd_dat.HorCoo;
        obs_data.MeanSidTime=kwd_dat.MeanSidTime;
        if ~strcmp(obs_data.obj_name,kwd_dat.object_name)
            name_warn=['object name <> OBJNAME! ' obs_data.obj_name kwd_dat.object_name];
        else
            name_warn='';
        end
        
        
        
        %*******************Calculate Heliocentric correction*********************
        % This is currently done by interpolation on precalculated table which is
        % loaded from a mat file.
        % First look for vhelio mat file - in the object folder (top level)
        % this file contains a table with heliocentric velocity correction values
        % as function of MJD. The heliocentric correction is calculated by
        % interpolation on this table.
        % The table is generated from IRAF and converted to mat file
        % by matlab script.
        try % catch vhelio errors
            if do_helio
                
                load(fullfile(obj_folder,vhelio_fn),'vhelio_table');
                % 1st col= MJD 2nd col= HJD 3rd col=vhelio
                % find HJD by linear interpolation
                HJD=interp1(vhelio_table(:,1),vhelio_table(:,2),obs_data.MJD,'linear');
                % find VHELIO by linear interpolation
                VHELIO=interp1(vhelio_table(:,1),vhelio_table(:,3),obs_data.MJD,'linear');
                
                % for backward compatibility the params are inserted in Keywords array
                % Insert here the VHELIO and HJD additional keywords:
                idx=length(Keywords)+1;
                Keywords(idx+1,1)={'HJD'};
                Keywords(idx+1,2)={HJD};
                Keywords(idx+1,3)={[]};
                Keywords(idx+2,1)={'VHELIO'};
                Keywords(idx+2,2)={VHELIO};
                Keywords(idx+2,3)={[]};
                
                % add them also to obs_data structure
                obs_data.HJD=HJD;
                obs_data.VHELIO=VHELIO;
            else % if vhelio not calculated put HJD=VHELIO=NaN
                idx=length(Keywords)+1;
                Keywords(idx+1,1)={'HJD'};
                Keywords(idx+1,2)={NaN};
                Keywords(idx+1,3)={[]};
                Keywords(idx+2,1)={'VHELIO'};
                Keywords(idx+2,2)={NaN};
                Keywords(idx+2,3)={[]};
                HJD=NaN;
                VHELIO=NaN;
                % add them also to obs_data structure
                obs_data.HJD=NaN;
                obs_data.VHELIO=NaN;
                
                
                
            end % if do helio
        catch err% vhelio error
            fprintf('\n Vhelio problem for  %s :  vhelio file name: %s \n', obj_name, vhelio_fn);
            fprintf('Error: %s \n',err.message);
            obs_data.HJD=NaN;
            obs_data.VHELIO=NaN;
            HJD=NaN;
        end % try vhelio errors
        
        
        % calculate the relative phase of this measurement
        if meas_num==1
            obs_data.rphase=0;
        else
            obs_data.rphase=mod(HJD-xd(1).HJD,obs_data.period)/obs_data.period ;
            
        end % if meas num==1
        
        
        
        
        % *************calibration and bad order assignment **********************
        % reset  obs_data.bad_orders to zero (all are good)
        obs_data.bad_orders=zeros(num_orders,1);
        
        %------report if cal_rms exceeds the thershold---------------------
        cal_thr=0.1;
        if obs_data.cal_rms>=cal_thr
            calwarn='***cal***';
        else
            calwarn='';
        end
        
        
        
        % Create a bad order list based on the RMS value of the calib fit
        obs_data.bad_orders= cal.rms_order >= proc_params.cal_thr_ord;
        if proc_params.exclude_telluric
            % comment this section in the future
            %                 obs_data.bad_orders(1)=1;
            %                 obs_data.bad_orders(2)=1;
            %                 obs_data.bad_orders(3)=1;
            %                 obs_data.bad_orders(4)=1;
            %                 obs_data.bad_orders(5)=1;
            %                 obs_data.bad_orders(6)=1;
            %                 obs_data.bad_orders(7)=1;
            %                 obs_data.bad_orders(8)=1;
            %                 obs_data.bad_orders(9)=1;
            %                 obs_data.bad_orders(10)=1;
            
            % end of comment this section in the future
            
            obs_data.bad_orders(17)=1;
            obs_data.bad_orders(18)=1;
            obs_data.bad_orders(19)=1;
            obs_data.bad_orders(20)=1;
            obs_data.bad_orders(21)=1;
        end
        
        
        
        %**************************************************************************
        %
        % save the data into the same mat file
        matfn=fullfile(mat_path,matlist(meas_num).name);
        % if exist(matfn,'file')
        %     delete(matfn); % deletes existing mat file to prevent file size growth
        % end
        mat_file_name=matlist(meas_num).name;
        % save(matfn,'mat_file_name','obs_data','Keywords','spect','cal','-append');
        save(matfn,'mat_file_name','obs_data','Keywords','spect','cal');
        %
        
        
        % put exposure data to a structure that contains signal data from all the exposures
        % of a specific target
        
        xd(meas_num).name           =  matlist(meas_num).name;
        xd(meas_num).obj_name       =  obs_data.obj_name;
        xd(meas_num).HJD             =   obs_data.HJD;
        xd(meas_num).rphase         =   obs_data.rphase;
        
        xd(meas_num).airmass        =   obs_data.airmass;
        xd(meas_num).exposure       =   obs_data.exposure;
        xd(meas_num).max_signal     =   obs_data.max_signal;
        xd(meas_num).total_counts   =   obs_data.total_counts;
        
        
        xd(meas_num).snr            =    obs_data.snr;
        xd(meas_num).cal_rms        =   obs_data.cal_rms;
        
        fprintf('%-40s \t %-12.4f \t %-7.3f \t %-7.2f \t %-7.2f \t %-10.1f \t %-6.4e \t %-7.2f \t %-7.4f %s %s \n',...
            xd(meas_num).name,xd(meas_num).HJD,xd(meas_num).rphase,xd(meas_num).airmass,xd(meas_num).exposure,...
            xd(meas_num).max_signal,xd(meas_num).total_counts,xd(meas_num).snr,xd(meas_num).cal_rms,calwarn,name_warn);
        
        meas_jd(meas_num)=kwd_dat.JD; % remember the julian date of the exposure
        
    end  %loop on measurements
    
    
    
    
    
    
    
    
    
    
    % prepare exposure data for the target
    % This is the xd file saved in the target folder
    xd_fn=[obs_data.obj_name '_xd'];% exposure data mat file
    %
    xd=xd(:); % make it a column vector to enable convertion to dataset
    %
    xdds=struct2dataset(xd);
    
    %
    %
    % save the exposure data into an xls file
    
    export(xdds,'XLSfile',fullfile(obj_path, xd_fn)); % in xls format
    
    
    
    
    %**********************************************************************
    %                         RUN  UNICOR 
    %**********************************************************************
    
    
    if do_helio &&  proc_params.unicor_switch ... 
            && (strcmp(char(SBtype),'SB1') || strcmp(char(SBtype),'NA'))
        %
        run_unicor=true;
        %
    else
        run_unicor=false;
        % if there is no Vhelio data or run_unicor is false  do not run unicor
        
    end % if do_helio && unicor_switch && strcmp(char(SBtype),'SB1')
    
    
    if run_unicor
        
        %----------------------   Unicor Part   -----------------------------------
        % Run unicor
        % Auto-unicor is ready to be used.
        % instructions:
        % 1) Make sure a default template is saved in the "\mat" folder.
        %
        % 2) create an "input_struct" stucture: example:
        %             input_struct.obs_pathname = 'C:\eshel_data\HD67767\Spectra\mat'
        % 3) call unicor:
        %            unicor(input_struct)
        %
        %
        % create an "input_struct" stucture:
        % input_struct.obs_pathname = [work_path '\mat'];
        % % call unicor:
        %unicor(input_struct);
        % %
        try
            par_tmp                      = load('autorun_settings.mat'); % in unicor/DATA
            input_struct.par             = par_tmp.par;
            input_struct.obs_pathname    = fullfile(obj_path,'Spectra','mat');
            input_struct.obs_data_format = 'eShel';
            input_struct.par.P           = obs_data.period;
            
            input_struct.par.prog=target_list.prog{cur_target}; % transfer program name
            
            unicor(input_struct);
        catch err
            fprintf(['\n ERROR: Unicor failed to run. datapath:' mat_path '\n']);
            fprintf('\n %s \n',err.message);
        end
        
        
        
       
    end % if run unicor
    
    
    
    midnight=floor(now+1); % the coming midnight in matlab time
    midnight_ut=midnight-proc_params.time_zone/24; % midnight in UT
    jd_midnight=juliandate(datevec(midnight_ut));
    
    initial_phase=mod((jd_midnight-xd(1).HJD-6/24),obs_data.period)/obs_data.period ;
    final_phase=mod((jd_midnight-xd(1).HJD+6/24),obs_data.period)/obs_data.period ;
    phase_range1=[initial_phase, 0];
    phase_range2=[final_phase, 0];
    
     % plot the data in subplots
    rep_fig=figure;
    
    %rep_plot_title=[obs_data.obj_name ' observations updated for  ' datestr(now,'dd-mmm-yyyy')];
    rep_plot_title= sprintf('%s  observations updated for %s \n Program: %s ',...
        obs_data.obj_name,datestr(now,'dd-mmm-yyyy'),target_list.prog{cur_target});
    set(rep_fig, 'Position', [100 200 800 480]);
    annotation(rep_fig,'textbox',...
        [0.2 0.93 0.7 0.06],...
        'String',rep_plot_title,...
        'HorizontalAlignment','center',...
        'FontWeight','bold',...
        'FontSize',12,...
        'FitBoxToText','on',...
        'EdgeColor','none');
    
    
    
    
    %===================  plot SNR vs HJD =========================
    
    %
    snr_HJD_plot = axes('Parent',rep_fig,'YMinorTick','on','YMinorGrid','on',...
        'YGrid','on',...
        'XGrid','on',...
        'Position',[0.12 0.66 0.775 0.25],...
        'FontSize',12);
    box(snr_HJD_plot,'on');
    hold(snr_HJD_plot,'all');
    % Create ylabel
    ylabel('SNR','FontSize',12);
    % Create xlabel
    xlabel('Measurement Date [Days from Date of Report]','FontWeight','bold','FontSize',12);
    
      plot(xdds.HJD-jd_midnight,xdds.snr ,'Parent',snr_HJD_plot,'MarkerSize',15,'Marker','.','LineStyle','none');
    
      %==================== plot SNR vs rPhase ======================
    
    %
    
    
    snr_phase_plot = axes('Parent',rep_fig,'YMinorTick','on','YMinorGrid','on',...
        'YGrid','on',...
        'XGrid','on',...
        'Position',[0.12 0.3 0.775 0.25],...
        'FontSize',12);
    box(snr_phase_plot,'on');
    hold(snr_phase_plot,'all');
    
    % Create ylabel
    ylabel('SNR','FontSize',12);
    
    % Create xlabel
    xlabel('rPhase','FontWeight','bold','FontSize',12);
    
    
    
    
    %
    % Create plot
    plot(xdds.rphase,xdds.snr,...
        'Parent',snr_phase_plot,'MarkerSize',15,'Marker','.','LineStyle','none');
    
    % green triangle for start
    plot(phase_range1(:,1),phase_range1(:,2),...
        'Parent',snr_phase_plot,'MarkerFaceColor',[0 1 0],...
        'MarkerSize',12,'Marker','^','LineStyle','none');
    
    %red triangel for end
    plot(phase_range2(:,1),phase_range2(:,2),...
        'Parent',snr_phase_plot,'MarkerFaceColor',[1 0 0],...
        'MarkerSize',12,'Marker','^','LineStyle','none');
    
    
    
    % create a text box with the relevant data
    % Create textbox
    system_data_text=cell(2,1);
    system_data_text{1}=sprintf('%s     No.of Meas.: %d     Magnitude(V)= %4.1f\n',...
        char(obj_name),nmeas,obs_data.mag);
    system_data_text{2}=sprintf('Period: %5.2f days     SBtype= %s    Spectral Type: %s ',...
        period,char(obs_data.SBtype) , char(target_list.type(cur_target)));
    
    annotation(rep_fig,'textbox',...
        [0.14 0.04 0.77 0.17],...
        'String',system_data_text,...
        'FontWeight','bold',...
        'FontSize',12,...
        'FitBoxToText','on',...
        'BackgroundColor',[0.7 0.8 1]);
    
    % =========================Save all the plots in the target folder=========
    
    try  % catch plot save errors
        
        %save the spectra plot as a figure file
        saveas(spec_fig,fullfile(obj_path, [obs_data.obj_name '_' target_list.prog{cur_target} '_spectra.fig']));
        close(spec_fig);
        %save the calrms plot as a figure file
        
        
        %save the report figue plot as a figure file
        saveas(rep_fig,fullfile(obj_path, [obs_data.obj_name '_' target_list.prog{cur_target} '_meas.fig']));
        saveas(rep_fig,fullfile(obj_path, [obs_data.obj_name '_' target_list.prog{cur_target} '_meas.png']));
        close(rep_fig);
        
    catch err
        fprintf('Plot save Error in %s:\n %s \n',obj_name,err.message);
    end % catch plot save errors
   % close all;
  
   %-----------------------------------------------------------------------
   %               Update target_list 
   %-----------------------------------------------------------------------
   cur_jd=juliandate(now);
   djd=cur_jd-meas_jd;
    djd=djd(:);
    current_target_last_meas=floor(min(djd)); % days since last meas
   
   
   target_list.last(cur_target)=current_target_last_meas;
    
    target_list.nmeas(cur_target)= nmeas;
    
    %put ' in fornt of the RA to prevent excel from interpreting the number as time
    target_list.RA{cur_target}=['''' RA];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    meridian_data=meridian_calc(RA,proc_params.time_zone,proc_params.night_length, 'Wise');
    
    
    
    target_list.meridian(cur_target)=cellstr(meridian_data.meridian_hour_string);
    target_list.observable(cur_target)=meridian_data.observable;
        
   

%set priority 2 for all that have more than minimum_measurements and are
%not designated special priority  4 and bigger
if nmeas>=proc_params.night_length;
    if target_list.priority(cur_target)<4;
        target_list.priority(cur_target)=2;
    end
end
   
   
 clear('xd'); % delete xd variable before next target in the loop  
   
   
   
   
   
   
   
   
    
end %loop on targets


end

