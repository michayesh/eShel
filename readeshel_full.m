function spectrum = readeshel_full( filename )
%Reads eShel processed files and extract the full spectrum
%   Input: filename = object filename
%   Output:
%   spectrum 'PTUNG_nnA'
% 
info=fitsinfo(filename);
% keywords=info.PrimaryData.Keywords;%get the keywords

% extract from info the start wavelength for the specific order
% j=1; % j counts the number of spectra extensions processed
% k=1; % k counts the number of signal (raw) extensions read
% for i=1:length(info.Image)-1 % read the FULL part
%     if ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'A'))
%         %look only for images with A in their name - raw signals
%         sig(k).data=fitsread_binary_benny(filename,'image',i);
%         k=k+1;
%     elseif  ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'B'))  
        %look only for images with B in their name - spectraly calibrated
        full_index=length(info.Image);
        spectrum.filename=filename;
        spectrum.Keywords=info.PrimaryData.Keywords;%put the primary header in every spectrum piece
        spectrum.extname=info.Image(end).Keywords{strcmp('EXTNAME',info.Image(end).Keywords(:,1)),2};
       spectrum.deltalam= info.Image(end).Keywords{strcmp('CDELT1',info.Image(end).Keywords(:,1)),2};
        spectrum.lamstart=info.Image(end).Keywords{strcmp('CRVAL1',info.Image(end).Keywords(:,1)),2};
       spectrum.lamlen=info.Image(end).Keywords{strcmp('NAXIS1',info.Image(end).Keywords(:,1)),2};
        spectrum.data=fitsread_binary_benny(filename,'image',full_index);
        lamend=spectrum.deltalam*(spectrum.lamlen-1)+spectrum.lamstart;
        lambda=spectrum.lamstart:spectrum.deltalam:lamend;
        spectrum.lam=lambda';
        
    
