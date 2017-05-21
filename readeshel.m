function [s,sig]=readeshel(filename)
% reads eshel spectra from audela fits files.
% input:
% processed eshel object file
% Outputs:
%  s- structure array with wavelength calibrated components
%(those containing the 'B' in the %extension name) -see details below
% sig -Raw signal components (those containing the 'A' in the extension name)

%==========================================================================
% The spectra of the orders appear as a secondary exteintion of type 'image'. 
% It is a vector of evenly spaced values of the spectrum for the specific order.
% s is a sturcture array. an element for each one of the orders
% j,k order number
%s(j).filename - the original fits file name
%s(j).Keywords - the primary extension  Keywords from the fits file header
%s(j).extname - extension name that the spectrum was read in the format:...
% ... ('P_1B_ordernum')
% s(j).deltalam, s(j).lamstart,  s(j).lamlen are the start wavelength, ...
% ... delta wavelength and length of the wavelength vector (in Angstrom)
%s(j).data - the spectrum flux values
%s(j).lam - is the wavelength array in Angstrom
%==========================================================================
%The info structure read by info=fitsinfo(filename) of the fits file is ...
% ... a structure that contains the information on the structure of the
% data in the file.
%info.Contents - contains an array of cells with strings defining the type of
%data in each of the secondary extensions.
% info.Image - contains an array with length = number of image extensions
% each array element is a structure containing
%DataType, Size,DataSize, Offset,  MissingDataValue, Intercept,
%Slope,Keywords. 
% info.Image(i).Size = number of data elements
% info.Image(i).Keywords is a cell array that hold information about the
% specific image: 
% info.Image(i).Keywords{:,1} contains strings with the keyword names
% info.Image(i).Keywords{:,2} gives the value of the keyword
% info.Image(i).Keywords{:,3} gives a short explanation of the meaning of the keyword (string).
% In our case we are interested in the follwoing elements:
% info.Image(i).Keywords{4,2} NAXIS1 which gives the length of the spectrum array
% info.Image(i).Keywords{7,2} EXTNAME gives the name of the extension given
% by the eshel softwrae (of the format 'P_1X_order_number' X is A for raw spectra and B for wavelength calibrated spectra)
%  info.Image(i).Keywords{10,2} 'CRVAL1' is the starting wavelength of the
%  arrray
% info.Image(i).Keywords{11,2} 'CDELT1' is the wavelength step
% info.Image(i).Keywords{12,2} 'CTYPE1' is the label of the x axis (here'wavelength')
% info.Image(i).Keywords{13,2} 'CUNIT1' is the units of this axis (here 'Angstrom')
% =========================================================================
%updated by Micha 22/12/13 - added reading the signal vector
% uses:
%fitsinfo (standatrd matlab) fitsread_binary_benny(modified function that
%reads fits files from benny 
%==========================================================================
info=fitsinfo(filename);
% extract from info the start wavelength for the specific order
j=1; % j counts the number of spectra extensions processed
k=1; % k counts the number of signal (raw) extensions read
for i=1:length(info.Image)-1 % do not read the FULL part
    if ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'A'))
        %look only for images with A in their name - raw signals
        sig(k).data=fitsread_binary_benny(filename,'image',i);
        k=k+1;
    elseif  ~isempty(strfind(info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2},'B'))  
        %look only for images with B in their name - spectraly calibrated
        s(j).filename=filename;
        s(j).Keywords=info.PrimaryData.Keywords;%put the primary header in every spectrum piece
        s(j).extname=info.Image(i).Keywords{strcmp('EXTNAME',info.Image(i).Keywords(:,1)),2};
        s(j).deltalam= info.Image(i).Keywords{strcmp('CDELT1',info.Image(i).Keywords(:,1)),2};
        s(j).lamstart=info.Image(i).Keywords{strcmp('CRVAL1',info.Image(i).Keywords(:,1)),2};
        s(j).lamlen=info.Image(i).Keywords{strcmp('NAXIS1',info.Image(i).Keywords(:,1)),2};
        s(j).data=fitsread_binary_benny(filename,'image',i);
        lamend=s(j).deltalam*(s(j).lamlen-1)+s(j).lamstart;
        lambda=s(j).lamstart:s(j).deltalam:lamend;
        s(j).lam=lambda';
        j=j+1;
    end
end;
