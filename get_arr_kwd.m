function value=get_arr_kwd(array,keyword)
% fit files: Gets a  value of a keyword from fits file header keyword array
% returns the value as string - you have to know what to expect and convert
% it to the proper format
% input: array= a keyword array 1st col= keyword name 2nd col= keyword
% value
%        keyword = a string with the keyword name as it appears in the header
% uses: 
% Micha  11/11/13
% ========================================================================

mask=strcmp(keyword,array(:,1));
if any(mask) 
 value= array{mask,2};
else
    value=''; %return empty string if not found
   warning('eShel:get_arr_kwd','Keyword not found');
    
end
end