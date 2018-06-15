FILENAME REFFILE '/folders/myfolders/CleanedDataForANOVA.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.KaggData replace;
	GETNAMES=YES;
RUN;


proc means data=KaggData n mean max min range std fw=8;
class KitchenQual Neighborhood;
var SalePrice;
output out=meansout mean=mean std=std;
title 'Summary of Sales Prices';
run;

/* Remove the spurious obervations */
data summarystats;
set meansout;
if _TYPE_=0 then delete;
if _TYPE_=1 then delete;
if _TYPE_=2 then delete;
run;

/* Prepare the data to be plotted, calc upper and lower ends of standard dev bars */
data plottingdata;                                                                                                      
   set summarystats;
   lower=mean - std;                                                                                                                 
   upper=mean + std;                                                                                                                             
run;

/* Sort the data by Neighborhood */
proc sort data=plottingdata;
by Neighborhood;
run;

proc print data=plottingdata;
run;

/* Plotting the data */
proc sgplot data=plottingdata;                                                                                                  
   scatter x=Neighborhood y=mean / group=KitchenQual yerrorlower=lower                                                                                            
                           yerrorupper=upper                                                                                           
                           markerattrs=(symbol=CircleFilled) ;                                                                
   series x=Neighborhood y=mean / group=KitchenQual ;    
   title1 'Plot Means with Standard Deviations Bars from Calculated Data';   
   label mean='Average Sales Price';
run;   

/* Above Plot shows that spread is higher at some higher values of mean, hence
Non Constant variance could be present( points at site No Ridge). Residual plot would clarify further */

proc glm data=KaggData plots=(DIAGNOSTICS RESIDUALS);
class KitchenQual Neighborhood;
model SalePrice = KitchenQual Neighborhood KitchenQual*Neighborhood;
run;
 
/* Residual Plots show funnel like pattern and also skewed residuals.
Log Transformation could help in rectifying such situation */
  
/* Performing Log Transformation and Model Assumption Validation */ 
data kaggdata;
set kaggdata;
LogSalePrice = Log(SalePrice); /* In */
run;

proc sgscatter data=Work.Kaggdata;
plot SalePrice*GrLivArea;
run;

/* Houses with Gr Living Area > 4000 are not representative of other houses in data set
hence removing there outlier values */
data kaggdata;
set kaggdata;
if GrLivArea < 4000;
run;

proc means data=KaggData n mean max min range std fw=8;
class KitchenQual Neighborhood;
var LogSalePrice;
output out=meansoutlog mean=mean std=std;
title 'Summary of Log Sales Prices';
run;

/* Remove the spurious obervations */
data summarystatsafterlogT;
set meansoutlog;
if _TYPE_=0 then delete;
if _TYPE_=1 then delete;
if _TYPE_=2 then delete;
run;

/* Prepare the data to be plotted, calc upper and lower ends of standard dev bars */
data plottingdataafterlogT;                                                                                                      
   set summarystatsafterlogT;
   lower=mean - std;                                                                                                                 
   upper=mean + std;                                                                                                                             
run;

/* Sort the data by Neighborhood */
proc sort data=plottingdataafterlogT;
by Neighborhood;
run;

proc sgplot data=plottingdataafterlogT;                                                                                                  
   scatter x=Neighborhood y=mean / group=KitchenQual yerrorlower=lower                                                                                            
                           yerrorupper=upper                                                                                           
                           markerattrs=(symbol=CircleFilled) ;                                                                
   series x=Neighborhood y=mean / group=KitchenQual ;    
   title1 'Plot Means with Standard Deviations Bars from Calculated Data';   
   label mean='Average Log Sales Price';
run;   

/* Storing Comparison Table to a dataset so that only statistically
significant differences can be extracted */
ods output diffs=ComparisonData;
proc mixed data=KaggData plots=RESIDUALPANEL;
class KitchenQual Neighborhood;
model LogSalePrice = KitchenQual Neighborhood KitchenQual*Neighborhood;
lsmeans KitchenQual*Neighborhood/pdiff diff adjust=tukey;
run; 
ods output on;
ods exclude none;

proc print data=ComparisonData;
run;

/* Find Same site Diff in Kitchen Qual on Sale Price */
/* This further bolsters that interaction is important as we see for some sites that
differences in Kitchen Qual on Price are not significant but for few sites, diff are highly significant */
data CompareSameSite_KitchenQual;
set ComparisonData;
if Neighborhood = _Neighborhood;
run;

/* To find all ab kind off means that are statistically significant */
/* 863 off 2485 pairs are statistically significant, interaction is important one and complex in nature as
nearly 25% of pairs differ */
data StatisticallySigDiffs;
set ComparisonData;
if AdjP <= 0.05;
run;


