function spectrum= concat_orders( spect )
% Concatenates orders to a single spectrum
%   Input: 
% spect - structure generated by the pipeline
%   output:
%       spectrum a two field structure
%       spectrum.lam= lambda vector
%       spectrum.spec = spectrum (flattenned and normed to 1)
% the order spectra are concatenated without elimination of over lapping
% data!


llam=[];lspec=[];
            
            % create a continuous plot of the exposure spectrum
            num_orders=length(spect);
            for order=1:num_orders
                
                llam=[llam ; spect(order).lam];
                lspec=[lspec ; spect(order).data] ;
                
            end % order loop
            spectrum.lam=llam;
            spectrum.spec=lspec;


