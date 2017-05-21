function B = planck_um( lambda,temperature )
% compute black body emittance [W/cm²/µm]
%  lambda in µm (may ba a vector), temperature K
% %/********************** COMPUTE_BLACK_BODY ***********************/
% /* Retourne l'émittance d'un corps noir en w/cm2/A          */
% /*****************************************************************/
% double compute_black_body(double lambda,double temperature)
% {
% double c1=3.739876e4;
% double c2=1.438769e4;
% double v;
% 
% lambda=lambda/10000.0; // conversion des A en microns
% v=c1/pow(lambda,5.0)*(1.0/(exp(c2/lambda/temperature)-1));
% return v;
% }
C1=3.739876e4;
C2=1.438769e4;

 B=(C1./lambda.^5).*(1.0./(exp(C2./lambda/temperature)-1));

end

