function [keywords,tung,blaze] = readeshel_flat( filename )
%Reads eShel flat files and extract the tungsten profiles
%   Input: filename = flat filename
%   Output:
%   tung tungsten profiles 'PTUNG_nnA'
%  blaze - normalized blaze profile 'P_nnA'
info=fitsinfo(filename);
keywords=info.PrimaryData.Keywords;%get the keywords
j=1; % j counts the number of spectra extensions processed
k=1; % k counts the number of signal (raw) extensions read
for i=1:length(info.Image) % do not read the FULL part
    if ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'P_1A'))
        %look only for images with P_1A in their name - smoothed tungsten prof
        blaze(k).extname=info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2};
        blaze(k).data=fitsread_binary_benny(filename,'image',i);
        k=k+1;
    elseif  ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'PTUNG_1A'))  
        %look only for images with PTUNG_1A in their name - raw tungsten profiles
        
        tung(j).extname=info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2};
        tung(j).data=fitsread_binary_benny(filename,'image',i);
        j=j+1;
    end
end;


end

