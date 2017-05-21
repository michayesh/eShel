function [nspec,conti]=clean_norm(spec,width,quantval,method,varargin)
% A function to clean NaN values and normalize the input spectrum by a
% fitted polynomial of degree npoly. It also applies a cosine bell window
% of a certain width
% inputs:
% spec - structure array of length number of orders
% width - 
% quantval
% method: 'simple','simple-robust'
% 
no=numel(spec);
nspec=spec;
conti=spec;

for i=1:no
    
    % retrieve data and form 1xN
    data = reshape(spec(i).data,1,numel(spec(i).data));
    lam  = reshape(spec(i).lam,1,numel(spec(i).lam));
    
    % clean nan values
    dataclean = data(~isnan(data));
    lamclean  = lam(~isnan(data));
    
    % erase edges for the computation of the continuum
%     dataclean(1:50)       = quantile(dataclean(1:50),quantval(1));
%     dataclean(end-50:end) = quantile(dataclean(end-50:end),quantval(end));
    data4cont=dataclean;
    nl=numel(dataclean);
 
    % apply padding with the mean at each edge
    margin=ceil(numel(data4cont)./width);
    Npad=floor(margin(1)/4);
    mean1=quantile(data4cont(1:Npad),quantval);
    mean2=quantile(data4cont(end-Npad+1:end),quantval);
    paddata=[ones(1,Npad)*mean1, data4cont, ones(1,Npad)*mean2];
    
    
    switch method
        case {'simple','simple-robust'}
            % quartile filtering
            continuum=quantfilt(paddata,margin,quantval,margin);
            % fit by smooth filter
            continuum=smooth(continuum,margin);
            continuum=continuum(1+Npad:end-Npad);
        case {'differential','differential-robust'}
            % differential quartile filtering
            filterwid = margin(1) + (margin(2)-margin(1))*tukeywin(numel(paddata),0.7);
            continuum = quantfiltdiff(paddata,filterwid,quantval);
            continuum = smooth(continuum,median(margin));
            continuum = continuum(1+Npad:end-Npad);
    end
    
    % normalize
    datanorm   = dataclean./continuum';
    
    % check if datanorm is ones
    whereones = find(abs(datanorm-1)<=1e-10);
    
    if ~isempty(strfind(method,'robust')) && numel(whereones)<numel(datanorm)
        % rough estimation of the "1" level of the normalized spectrum
        contilevel = quantile(datanorm,0.75);
        
        % pre-estimation of the noise        
        if numel(varargin)==1
            noise = varargin{1};
        else
            ordercentroid = floor(numel(datanorm)/2);
            residcentroid = datanorm(ordercentroid-500:ordercentroid+500)-medfilt1(datanorm(ordercentroid-500:ordercentroid+500),10);
            noisecentroid = std(residcentroid(50:end-50));
            noise         = noisecentroid./sqrt(continuum/median(continuum(ordercentroid-500:ordercentroid+500)));
            noise         = reshape(noise,1,numel(noise));
            %noise = sqrt(sum((datanorm(datanorm>=contilevel)-contilevel).^2)/numel(find(datanorm>=contilevel)));
        end
        
        % match the continuum level with 1 and correct the continuum estimation
        okpix           = datanorm-contilevel>=-2*noise & datanorm-contilevel<=4*noise;
        xfit            = find(okpix);
        xfit            = xfit - median(xfit);
        [pcoeff,dum,mu] = polyfit(xfit,datanorm(okpix),1);
        floorlevel      = polyval(pcoeff,((1:nl)-mu(1))/mu(2));
        datanorm        = datanorm./floorlevel;
        continuum       = continuum.*floorlevel';
        
        % new evaluation of the noise level
        if numel(varargin)==1
            noise = varargin{1};
        else
            ordercentroid = floor(numel(datanorm)/2);
            residcentroid = datanorm(ordercentroid-100:ordercentroid+500)-medfilt1(datanorm(ordercentroid-500:ordercentroid+100),50);
            noisecentroid = std(residcentroid(50:end-50));
            noise         = noisecentroid./sqrt(continuum/median(continuum(ordercentroid-500:ordercentroid+500)));
            noise         = reshape(noise,1,numel(noise));
        end
        
        % exclude all points that are less than 1-noise or more than
        % 1+4sigma (+10 pixel on each side)
        %mask     = double(excpix);
        %convmask = conv(mask,ones(1,10),'same');
        %excpix   = convmask>0;
        excpix   = (datanorm-1)<-noise | (datanorm-1)>4*noise;
        numNoise = 0;
        % %%%%%% unclear ???? %%%%%%
        while numel(find(excpix))>0.5*numel(datanorm)
            numNoise = numNoise+1;
            excpix   = (datanorm-1)<-(1+numNoise)*noise | (datanorm-1)>(4+numNoise)*noise;
            
        end
        
%         %%%%%%%%%%%%%%%%%%%%%% unclear
        
        % new continuum interpolated through excluded pixels
        oldcontinuum = continuum(~excpix);
        oldpix       = find(~excpix);
        newcontinuum = interp1(oldpix,oldcontinuum',1:nl,'linear');
        % put NaNs on the edge of the orders where the normalization is uncertain
        inner = find(~excpix,1):find(~excpix,1,'last');
        tmpcontinuum        = newcontinuum;
        newcontinuum(:)     = NaN;
        newcontinuum(inner) = tmpcontinuum(inner);
        
        % new datanorm
        newdatanorm = dataclean./newcontinuum;
        
        % clean again all nans
        nanlocs      = ~isnan(newdatanorm);
        newdatanorm  = newdatanorm(nanlocs);
        lamclean     = lamclean(nanlocs);
        newcontinuum = newcontinuum(nanlocs);
    else
        newdatanorm  = datanorm;
        newcontinuum = continuum';
    end
    
    % save and return
    %converted to column vector (Micha)
    nspec(i).lam  = lamclean';
    nspec(i).data = newdatanorm';
    conti(i).lam  = lamclean';
    conti(i).data = newcontinuum';
end

% % overall normalization by the median
% overall_norm1 = quantile([nspec.data],0.95);
% overall_norm2 = median([nspec.data]);
% for i=1:no
%     % save and return
%     nspec(i).data = nspec(i).data/overall_norm1;
%     conti(i).data = conti(i).data/overall_norm2;
% end

