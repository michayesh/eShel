function  attachments  = create_attachments( target_list,targets2run )
% This fuction creates an array of files (attachments) to be attached to
% the pipeline e-mail
% Inputs:
% target list -  a list of targets based on the master target list format
% targets2run - - a vector of target indices in target_list to process
%   it operates in the data folder 
data_path=pwd;
attachments=cell(500,1); 

targets2run=targets2run(:)'; % row vector needed for loop
for cur_target= targets2run 
    
        obj_folder=target_list.name(cur_target);
        obj_path=fullfile(data_path,char(obj_folder));
        obj_name=target_list.name(cur_target);
   
        
%         rv_fig_fn=fullfile(obj_path,...
%             'Velocity',   [obj_name '-' target_list.prog{cur_target} 'RV.fig']);
%         rv_png_fn=fullfile(obj_path,...
%             'Velocity',   [obj_name '-' target_list.prog{cur_target} 'RV.jpg']);
           rv_fig_fn= [char(obj_name) '-' target_list.prog{cur_target} 'RV.fig'];            
           rv_png_fn=[char(obj_name) '-' target_list.prog{cur_target} 'RV.jpg']; 
         %
        if exist(fullfile(obj_path,'Velocity', rv_png_fn),'file')
            
            new_index=find(cellfun(@isempty, attachments),1);
            attachments{new_index}=fullfile(obj_path,'Velocity', rv_png_fn);
            
        end  %if exist(rv_png_fn,'file')
        
        if exist(fullfile(obj_path,'Velocity', rv_fig_fn),'file')
            
            new_index=find(cellfun(@isempty, attachments),1);
            attachments{new_index}=fullfile(obj_path,'Velocity', rv_fig_fn);
            
            
        end  %if exist(rv_fig_fn,'file')
           
           
           
           
           
           
           
           
%         sol_png_fn=fullfile(obj_path,[obj_name '-' target_list.prog{cur_target} '_Sol.png']);
%         sol_fig_fn=fullfile(obj_path,[obj_name '-' target_list.prog{cur_target} '_Sol.fig']);
       
            sol_png_fn=[char(obj_name) '-' target_list.prog{cur_target} '_Sol.png'];
            sol_fig_fn=[char(obj_name) '-' target_list.prog{cur_target} '_Sol.fig'];
       

        
        %************ prepare solution plot attachment  *****************************************
        
        %Check if the files exist
        if exist(fullfile(obj_path,sol_png_fn),'file')
            new_index=find(cellfun(@isempty, attachments),1);
            attachments{new_index}=fullfile(obj_path,sol_png_fn);
        end % if exist(sol_png_fn,'file')
        
        if exist(fullfile(obj_path,sol_fig_fn),'file')
            new_index=find(cellfun(@isempty, attachments),1);
            attachments{new_index}=fullfile(obj_path,sol_fig_fn);
        end % if exist(sol_fig_fn,'file')
        
        
        
        
        
        
        
        
end %for cur_target= targets2run 












end

