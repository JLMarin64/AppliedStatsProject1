/*
 * Import the Training Data Set
 */
PROC IMPORT OUT= WORK.train 
            DATAFILE= "/home/marinfamily1010/sasuser.v94/Data/train.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;




proc sql;
create table work.train3 as 

/*Dividing the GrLivArea by 100*/
select Neighborhood, GrLivArea/100 as GrLivArea, SalePrice
from train 
where Neighborhood in ('NAmes','Edwards','BrkSide')

order by Neighborhood;
run;


/*
 * At least one neighborhood has a different slope.  Using Different slopes model. 
 */

proc sgscatter data = work.train3;
by Neighborhood;
plot SalePrice * GrLIvArea;
run;


proc glm data = work.train3 plots = ALL;
class Neighborhood (ref = "NAmes");
model SalePrice = GrLIvArea | Neighborhood / solution clparm;
output out = cookd cookd = cookd;
run;

/*Limiting the high cookd value and the high leverage points out of data (influential points)*/

proc sql;
create table work.train4 as 
select Neighborhood, GrLivArea as GrLivArea, SalePrice
from COOKD 
where Neighborhood in ('NAmes','Edwards','BrkSide')
and cookd < 2.74
and GrLivArea < 30
order by Neighborhood;
run;

/*Re-running scatter and model without influential points*/

proc sgscatter data = work.train4;
by Neighborhood;
plot SalePrice * GrLIvArea;
run;


proc glm data = work.train4 plots = ALL;
class Neighborhood (ref = "NAmes");
model SalePrice = GrLIvArea | Neighborhood / solution clparm;
output out = cookd2 cookd = cookd2;
run;
 






