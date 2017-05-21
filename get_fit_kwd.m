function value=get_fit_kwd(fit_file_name,keyword)
% fit files: Gets a  value of a keyword for fits file header keywords
% returns the value as string - you have to know what to expect and convert
% it to the proper format
% input: fit_file_name= file name ( a proper fit file)
%        keyword = a string with the keyword as it appears in the header
% uses: fitsinfo
% Micha  28/8/13
% ========================================================================
info=fitsinfo(fit_file_name);
mask=strcmp(keyword,info.PrimaryData.Keywords(:,1));
if any(mask) 
 value= info.PrimaryData.Keywords{mask,2};
else
    value=''; %return empty string if not found
   warning('eShel:get_fit_kwd','Keyword not found');
    
end
end