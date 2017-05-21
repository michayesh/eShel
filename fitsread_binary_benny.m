function data = fitsread_binary_benny(varargin)
%FITSREAD Read data from FITS file
%
%   DATA = FITSREAD(FILENAME) reads data from the primary data of the FITS
%   (Flexible Image Transport System) file FILENAME.  Undefined data values
%   will be replaced by NaN.  Numeric data will be scaled by the slope and
%   intercept values and is always returned in double precision.
%
%   DATA = FITSREAD(FILENAME,OPTIONS) reads data from a FITS file according to
%   the options specified in OPTIONS.  Valid options are:
%
%   EXTNAME      EXTNAME can be either 'Primary','Table','BinTable', 'Image', or
%                'Unknown' to read data from the primary data array, ASCII
%                table extension, Binary table extension, Image extension or
%                an unknown extension.  If there is more than one of the
%                specified extension, the one found first in the
%                file will be read. DATA for ASCII and Binary table
%                extensions will be a 1 by the number
%                of fields cell array. The contents of a FITS file can be
%                located in the Contents field of the structure
%                returned by FITSINFO.
%
%   EXTNAME,IDX  Same as EXTNAME except if there is more than one of the
%                specified extension type, the IDX'th one is read.
%
%   'Raw'        DATA read from the file will not be scaled and undefined
%                values will not be replaced by NaN.  DATA will be
%                the same class as it is stored in the file.
%
%   See also FITSINFO.

%   Copyright 2001-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.9 $  $Date: 2007/11/26 20:36:11 $

%Parse Inputs
[filename,extension,index,raw] = parseInputs(varargin{:});

%Get file info. FITSINFO will check for file existence.
info = fitsinfo(filename);

switch lower(extension)
    case 'primary'
        data = readprimary(info,raw);
    case 'ascii'
        data = readasciitable(info,index,raw);
    case 'binary'
        data = readbinarytable(info,index,raw);
    case 'image'
        data = readimage(info,index,raw);
    case 'unknown'
        data = readunknown(info,index,raw);
end
%END FITSREAD

function [filename,extension,index,raw] = parseInputs(varargin)
%Verify inputs are correct
estr = nargchk(1,4,nargin, 'struct');
if (~isempty(estr))
    error(estr);
end

filename = varargin{1};
extension = 'primary';
index = 1;
raw = 0;

allStrings = {'primary','image','bintable','table','unknown','raw'};
for k = 2:length(varargin)
    if (ischar(varargin{k}))
        idx = strmatch(lower(varargin{k}), allStrings);
        switch length(idx)
            case 0
                error('MATLAB:fitsread:unknownInputArgument', ...
                      'Unknown string argument: "%s."', varargin{k});
            case 1
                varargin{k} = allStrings{idx};
            otherwise
                error('MATLAB:fitsread:ambiguousInputArgument', ...
                      'Ambiguous string argument: "%s."', varargin{k});
        end
    else
        %Don't allow fitsread(filename,idx);
        if k==2
            error('MATLAB:fitsread:extensionIndex', ...
                'The extension index IDX must follow the extension name EXTNAME.');
        end
    end
end

for i=2:nargin
    switch lower(varargin{i})
        case 'primary'
            extension = 'primary';
        case 'bintable'
            extension = 'binary';
            if (i+1)<=nargin && isnumeric(varargin{i+1})
                index  = varargin{i+1};
            end
        case 'image'
            extension = 'image';
            if (i+1)<=nargin && isnumeric(varargin{i+1})
                index  = varargin{i+1};
            end
        case 'table'
            extension = 'ascii';
            if (i+1)<=nargin && isnumeric(varargin{i+1})
                index  = varargin{i+1};
            end
        case 'unknown'
            extension = 'unknown';
            if  (i+1)<=nargin && isnumeric(varargin{i+1})
                index  = varargin{i+1};
            end
        case 'raw'
            raw = 1;
    end
end
%END PARSEINPUTS

function data = readprimary(info,raw)
%Read data from primary data

data = [];
msg = 'Error reading file.  File may be an invalid FITS file or may be corrupt.';

if info.PrimaryData.DataSize==0
    return;
end

startpoint = info.PrimaryData.Offset;

%Data will be scaled by scale values BZERO, BSCALE if they exist
bscale = info.PrimaryData.Slope;
bzero = info.PrimaryData.Intercept;
nullvals = info.PrimaryData.MissingDataValue;

fid = fopen(info.Filename,'r','ieee-be');
if fid==-1
    error('MATLAB:fitsread:fileOpenPrimary', msg);
end
status = fseek(fid,startpoint,'bof');
if status==-1
    fclose(fid);
    error('MATLAB:fitsread:corruptFilePrimary', msg)
end
[data, count] = fread(fid,prod(info.PrimaryData.Size),['*' info.PrimaryData.DataType]);
fclose(fid);
if count<prod(info.PrimaryData.Size)
    warning('MATLAB:fitsread:truncatedData', ...
        'Problem reading primary data. Data has been truncated.');
else
    %Data is stored in column major order so the first two dimensions must be
    %permuted
    data = permute(reshape(data,info.PrimaryData.Size),...
        [2 1 3:length(info.PrimaryData.Size)]);
    %Scale data and replace undefined data with NaN by default
    if ~raw && ~isempty(nullvals)
        data(data==nullvals) = NaN;
    end
    if ~raw
        data = double(data)*bscale+bzero;
    end
end
%END READFITSPRIMARY

function data = readimage(info,index,raw)
%Read data from image extension

data = [];
msg = 'Error reading file.  File may be an invalid FITS file or may be corrupt.';

if ~isfield(info,'Image')
    error('MATLAB:fitsread:noImageExtensions', ...
        'File does not contain any Image Extensions.');
elseif length(info.Image)<index
    error('MATLAB:fitsread:extensionNumberImage', ...
        'File only contains %i Image extensions.', length(info.Image));
end

if info.Image(index).DataSize==0
    %No data
    return;
end

%Data will be scaled by scale values BZERO, BSCALE if they exist
bscale = info.Image(index).Slope;
bzero = info.Image(index).Intercept;
nullvals = info.Image(index).MissingDataValue;

startpoint = info.Image(index).Offset;

fid = fopen(info.Filename,'r','ieee-be');
if fid==-1
    error('MATLAB:fitsread:fileOpenImage', msg);
end
status = fseek(fid,startpoint,'bof');
if status==-1
    fclose(fid);
    error('MATLAB:fitsread:corruptFileImage', msg)
end
[data, count] = fread(fid,prod(info.Image(index).Size),['*' info.Image(index).DataType]);
fclose(fid);
if count<prod(info.Image(index).Size)
    warning('MATLAB:fitsread:truncatedData', ...
        'Problem reading image data. Data has been truncated.');
else
    %Data is stored in column major order so the first two dimensions must be
    %permuted
    %   data = permute(reshape(data,info.Image(index).Size),[2 1 3:length(info.Image(index).Size)]);
    %Scale data and replace undefined data with NaN by default
    if ~raw && ~isempty(nullvals)
        data(data==nullvals) = NaN;
    end
    if ~raw
        data = double(data)*bscale+bzero;
    end
end
%END READFITSIMAGE

function data = readbinarytable(info,index,raw)
%Read data from binary table

data = {};
msg = 'Error reading binary table extension.  File may be an invalid FITS file or may be corrupt.';
% Verify correct number of Binary Table Extensions.
if (~isfield(info,'BinaryTable'))
    error('MATLAB:fitsread:noBinaryExtensions', ...
        'File does not contain any Binary Table Extensions.');
elseif (length(info.BinaryTable) < index)
    error('MATLAB:fitsread:extensionNumberBintable', ...
        'File only contains %i Binary Table extensions.', ...
        numel(info.BinaryTable));
end
if (info.BinaryTable(index).DataSize == 0)
    %No data
    return
end

tscal = info.BinaryTable(index).Slope;
tzero = info.BinaryTable(index).Intercept;
nullvals = info.BinaryTable(index).MissingDataValue;

startpoint = info.BinaryTable(index).Offset;
fid = fopen(info.Filename,'r','ieee-be');
if fid==-1
    error('MATLAB:fitsread:fileOpenBintable', msg);
end
status = fseek(fid,startpoint,'bof');
if status==-1
    fclose(fid);
    error('MATLAB:fitsread:corruptFileBintable', msg)
end

data = cell(1,info.BinaryTable(index).NFields);
% Read data. Take care of complex data and scaling.
% Don't scale null values or characters
% TZERO and TSCAL are not allowed to be used with TFORM = 'X' (bit
% fields but this code will not catch this and the data will get scaled if
% the file does not follow the standard).

% Compute the length (in bytes) of a field
skipBytesTotal = getSkipBytes(1:info.BinaryTable(index).NFields, info.BinaryTable(index));
filePos = ftell(fid);

% For each field, read all of the records
for j=1:info.BinaryTable(index).NFields
    precision = sscanf(info.BinaryTable(index).FieldPrecision{j},'%s %*s');
    cmplx = sscanf(info.BinaryTable(index).FieldPrecision{j},'%*s %s');
    fieldSize = info.BinaryTable(index).FieldSize(j);
    rows = info.BinaryTable(index).Rows;
    % Compute that amount of bytes to skip between the
    % same field in each record.
    skipBytes = skipBytesTotal - getSkipBytes(j, info.BinaryTable(index));
    if fieldSize == 0 % Field has no data if size is zero
        data{j}(1:rows,1) = repmat({zeros(0,1)}, rows, 1);
    else
        % Seek to appropriate file position
        fseek(fid, filePos, 'bof');
        
        if(j > 1)
            skip = getSkipBytes(1:j-1, info.BinaryTable(index));
            fseek(fid, skip, 'cof');
        end
        % If the data is of character type, read into a cell array
        if strcmp(precision, 'char')
            fielddata = fread(fid, ...
                fieldSize*rows, ...
                [num2str(fieldSize) '*' precision '=>' precision], ...
                skipBytes);
            fields = reshape(fielddata, fieldSize, rows)';
            
%             original code:
%             for i=1:rows
%                 data{j}{i,1} = fields(i,:);
%             end

%             benny's code
            data{j} = fields;

        else % Numeric type
            precision = strrep(precision, 'bit', 'int');
            if isempty(cmplx) % Read real data
                fielddata = fread(fid, ...
                    fieldSize*rows, ...
                    [num2str(fieldSize) '*' precision '=>' precision], ...
                    skipBytes);
                fielddata = reshape(fielddata, fieldSize, rows).';
            else % Read complex data
                fielddataT = fread(fid, ...
                    fieldSize*2*rows, ...
                    [num2str(fieldSize*2) '*' precision '=>' precision], ...
                    skipBytes);
                fielddataT = reshape(fielddataT, fieldSize*2, rows);
                fielddata = complex(fielddataT(1:fieldSize,:), fielddataT(1+fieldSize:end,:)).';
            end
            if ~raw %convert to double format
                data{j}(1:rows,1:fieldSize) = double(fielddata);
            else
                data{j}(1:rows,1:fieldSize) = fielddata;
            end
        end
        % Add NaN's
        if ~raw && ~isempty(nullvals{j})
            data{j}(data{j}(:,:)==nullvals{j}) = NaN;
        end
        if ~raw && ~strcmp(precision, 'char') % Offset and scale the data
            data{j}(1:rows, 1:fieldSize) = ...
                data{j}(1:rows, 1:fieldSize)*tscal(j)+tzero(j);
        end
    end
end
fclose(fid);
%End READFITSBINARYTABLE

function sizeFields = getSkipBytes(fields, binaryTable)
% Compute the size of each of the fields
sizeFields = 0;
for j=fields
    fieldSize = binaryTable.FieldSize(j);
    precision = sscanf(binaryTable.FieldPrecision{j},'%s %*s');
    cmplx = sscanf(binaryTable.FieldPrecision{j},'%*s %s');
    if isempty(cmplx)
        cFactor = 1;
    else
        cFactor = 2;
    end
    sizeFields = sizeFields + cFactor*fieldSize*precisionSize(precision);
end

function sz = precisionSize(type)
% return the precision size, in bytes.
switch type
    case {'uint8' 'char' 'bit8'}
        sz = 1;
    case {'int16' 'bit16'}
        sz = 2;
    case {'int32' 'single' 'bit32'}
        sz = 4;
    case {'double' 'bit64'}
        sz = 8;
    otherwise
        error('MATLAB:fitsread:invalidPrecisionSize', ...
            'Incorrect precision value in FITS file (%s)', type);
end

function data = readasciitable(info,index,raw)
%Read data from ASCII table

data = {};
msg = 'Error reading ASCII Table extension.  File may be an invalid FITS file or may be corrupt.';

if ~isfield(info,'AsciiTable')
    error('MATLAB:fitsread:noASCIIExtensions', ...
        'File does not contain any ASCII Table Extensions.');
elseif length(info.AsciiTable)<index
    error('MATLAB:fitsread:extensionNumberAscii', ...
        'File only contains %i Ascii Table extensions.', ...
        length(info.AsciiTable));
end

if info.AsciiTable(index).DataSize==0
    %No data
    return;
end

%Scale factors: TSCALn TZEROn
tscal = info.AsciiTable(index).Slope;
tzero = info.AsciiTable(index).Intercept;
nullvals = info.AsciiTable(index).MissingDataValue;

startpoint = info.AsciiTable(index).Offset;

fid = fopen(info.Filename,'r','ieee-be');
if fid==-1
    error('MATLAB:fitsread:fileOpenAscii', msg);
end
status = fseek(fid,startpoint,'bof');
if status==-1
    fclose(fid);
    error('MATLAB:fitsread:corruptFileAscii', msg)
end

numRows = info.AsciiTable(index).Rows;
numCols = info.AsciiTable(index).NFields;

%For each field, determine data type, field width and implicit decimal point
%location from the FieldFormat.  The FieldFormat is a code defined by the
%FITS standard in the form of Tw.d, where T is a character representing the
%data type, w is the width of the field and d is the number of digits to the
%right of the decimal place (implied if not present in the read table data).

dataType = char(zeros(1, numCols));
decimal = zeros(1, numCols);
for i=1:numCols
    dataTypetemp = sscanf(info.AsciiTable(index).FieldFormat{i},' %c%*i',1);
    if isempty(dataTypetemp)
        warning('MATLAB:fitsread:fieldFormat', ...
            'Unable to determine field format of ASCII table. \nData in field %i will attempted to be read as a character array.',i);
        dataType(i) = 'A';
    else
        dataType(i) = dataTypetemp;
    end
    decimaltemp = sscanf(info.AsciiTable(index).FieldFormat{i},' %*c%*i.%i',1);
    if isempty(decimaltemp)
        decimal(i) = 0;
    else
        decimal(i) = decimaltemp;
    end
end

data = cell(1,numCols);
for i=1:numRows
    rowstart = ftell(fid);
    for j=1:numCols
        %Seek to start of each field and read data into char array
        fseek(fid,rowstart,'bof');
        fseek(fid,info.AsciiTable(index).FieldPos(j)-1,0);
        fielddatastr = fscanf(fid,'%c',info.AsciiTable(index).FieldWidth(j));

        %Check for undefined values
        if ((~isempty(nullvals{j})) && ...
            (~isempty(findstr(fielddatastr, nullvals{j}))))
          
            if (raw)

              fclose(fid);
              error('MATLAB:fitsread:rawNullValues', ...
                    'The ''raw'' option cannot be used for ASCII tables containing null values.');

            end

            if strcmp(dataType(j),'A')
                data{j}{i,1} = NaN;
            else
                data{j}(i,1) = NaN;
            end

            continue;
            
        end

        %Convert field Precision to format string
        fmtstr = prec2convstr(info.AsciiTable(index).FieldPrecision{j});

        if ~strcmp(dataType(j),'A')
            % Numeric fields that are blank have a value of 0 by default
            if all(fielddatastr==' ')
                %fielddata = 0;   % Note - I think this actually needs to be used.
                continue;
            else
                %Remove all blanks
                fielddatastr(findstr(fielddatastr,' ')) = '';
                %Replace all D with E for SSCANF
                fielddatastr(findstr(lower(fielddatastr),'d')) = 'E';
                %Separate exponent from fraction
                k = findstr('E',fielddatastr);
                if isempty(k)
                    % Not exponential notation.
                    % Cases like 345 or 40-10.  40-10 means 40E-10
                    [fielddata,count,errmsg,nextidx] = sscanf(fielddatastr,fmtstr,1);   % Note - I think this needs to actually be used.
                    if (nextidx-1)~=length(fielddatastr)
                        %Character other than '.', or 'E' found. This will be a '-'
                        %or '+'.
                        %Case like 40-10
                        fraction = fielddatastr(1:(nextidx-1));
                        exponent = num2str(sscanf(fielddatastr(nextidx:end),'%i',1));
                    else
                        %Not exponential notation
                        %Case like 345
                        fraction = fielddatastr;
                        exponent = 0;
                    end
                else
                    %Exponential Notation
                    %Found an 'E'.  Case like 40E10
                    fraction = fielddatastr(1:(k-1));
                    exponent = fielddatastr((k+1):end);
                end

                %Insert implicit decimal point
                if decimal(j) && isempty(findstr('.',fraction))
                    if length(fraction)<decimal(j)
                        %Zero pad
                        fraction = ['.' repmat('0',1,decimal(j)-length(fraction)) fraction];
                    else
                        fraction = [fraction(1:(length(fraction)-decimal(j))) '.' fraction((length(fraction)-decimal(j)+1):end)];
                    end
                end
                %Rebuild number as a string
                fielddatastr = [fraction 'E' exponent];
            end
        end

        %Convert to a number or string.
        fielddata = sscanf(fielddatastr,fmtstr);

        %Assign to output
        if strcmp(dataType(j),'A')
            data{j}{i,1} = char(fielddata);
        elseif ~raw
            %Scale data
            data{j}(i,1) = fielddata*tscal(j)+tzero(j);
        else
            data{j}(i,1) = fielddata;
        end
    end

    %Seek to beginning of next row.
    fseek(fid,rowstart,'bof');
    fseek(fid,info.AsciiTable(index).RowSize,0);
    if feof(fid)
        warning('MATLAB:fitsread:truncatedData', ...
            'Problem reading table data. Data has been truncated.');
        break;
    end
end
fclose(fid);
%END READASCIITABLE

function data = readunknown(info,index,raw)
%Read data from unknown data

data = [];
msg = 'Error reading file.  File may be an invalid FITS file or may be corrupt.';

if ~isfield(info,'Unknown')
    error('MATLAB:fitsread:noUnknownExtensions', ...
        'File does not contain any Unknown Extensions.');
elseif length(info.Unknown)<index
    error('MATLAB:fitsread:extensionNumberUnknown', ...
        'File only contains %i Unknown extensions.', length(info.Unknown));
end

if info.Unknown(index).DataSize==0
    return;
end

startpoint = info.Unknown(index).Offset;

%Data will be scaled by scale values BZERO, BSCALE if they exist
bscale = info.Unknown(index).Slope;
bzero = info.Unknown(index).Intercept;
nullvals = info.Unknown(index).MissingDataValue;

fid = fopen(info.Filename,'r','ieee-be');
if fid==-1
    error('MATLAB:fitsread:fileOpenUnknown', msg);
end
status = fseek(fid,startpoint,'bof');
if status==-1
    fclose(fid);
    error('MATLAB:fitsread:corruptFileUnknown', msg)
end
[data, count] = fread(fid,prod(info.Unknown(index).Size),['*' info.Unknown(index).DataType]);
fclose(fid);
if count<prod(info.Unknown(index).Size)
    warning('MATLAB:fitsread:truncatedData', ...
        'Problem reading data. Data has been truncated.');
else
    data = permute(reshape(data,info.Unknown(index).Size),...
        [2 1 3:length(info.Unknown(index).Size)]);

    if ~raw && ~isempty(nullvals)
        data(data==nullvals) = NaN;
    end
    %Scale data
    if ~raw
        data = double(data)*bscale+bzero;
    end
end
%END READUNKNOWN

function fmtstr = prec2convstr(format)
%convert precision string to format conversion string
switch format
    case {'Char','Unknown'}
        fmtstr = '%c';
    case {'Integer','Single','Double'}
        fmtstr = '%f';
end


