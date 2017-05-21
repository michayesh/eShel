function fy = quantfiltdiff(y,R,p)
% function for filtering with the p-quantile (p cumulative probability)
% with filter width R. Here R can be x-dependent.

Ny=numel(y);
fy=zeros(1,Ny);
for j=1:Ny
    fy(j)=quantile(y(max(1,j-floor(R(j)/2)):min(Ny,j+floor(R(j)/2))),p);
end
end