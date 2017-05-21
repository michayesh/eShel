function  figure_handle = plot_spectra(spectra,obj_data, span,dy )
% plots a group of spectra one above the other
%   inputs:
%       spectra - array of structures spectra(i).lam,spectra(i).spec
%       obj_data= struct with obj_data.name, obj_data.prog....
%       span - optional 0= no smoothing of the spectra (default) 
%       otherwise it is the span of the smooth function 
%       dy the step interval in y between the spectra (default=0.5)
spectra=spectra(:);
if nargin==1
    error('plot_spectra: Object data is missing');
    
elseif nargin==2
    span=0; dy=1;
elseif nargin==3
       dy=1;
    
end % if nargin
    

% Create figure
    figure_handle = figure;
    
    % Create axes
    axes1 = axes('Parent',figure_handle,'YGrid','on','XGrid','on');
    % ylim(axes1,[0 1.5]);
    box(axes1,'on');
    hold(axes1,'all');
    xlabel('Wavelength [A]');
    ylabel('Normalized Spectra');
    title({[obj_data.name '  ' obj_data.prog] ; datestr(now,'yyyymmddTHHMMSS') },'Interpreter','none');
    nsp=size(spectra,1);
    
    for s=1:nsp
        if span~=0
        spectra(s).spec=smooth(spectra(s).spec,span);
        end
     plot(axes1, spectra(s).lam, spectra(s).spec+dy*(s-1),'color',[rand rand rand]);
    hold on;
    end
    
    





end

