* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk

******************************************************************************
//ssc install coefplot
//ssc install ftools
//ssc install reghdfe
//ssc install tabout
//net install esplot, from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/")

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output"
global figures = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\figures"
global tables = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\tables"

use "${data_ztrax}\reg_data_RR_event_study", clear

********************************* HOUSE CHAR ********************************
	 * Three levels of housing char from most obs to fewest
	 global HC1 "LotSizeSquareFeet YearBuilt TotalBedrooms  TotalCalculatedBathCount i.build_quality"
	 global HC2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond"
	 global HC3 "LotSizeSquareFeet YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount i.build_quality i.heating i.aircond FireplaceNumber i.bath_code"
	 
******************************** EVENT STUDY *********************************
	// Model 1:	event study with FHSZ interaction on treatment
	// 		a: Separate events; no FHSZ dummy
	// 		b: Separate events; FHSZ dummy
	// 		c: Marginal effect; no FHSZ dummy
	// 		d: Marginal effect; FHSZ dummy
	// Model 2: event study with distance interaction on treatment
	// 		a: Separate events; no close dummy
	// 		b: Separate events; close dummy
	// 		c: Marginal effect; no close dummy
	// 		d: Marginal effect; close dummy

********************************** Model 1a **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 o.FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12 ///
				notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 o.notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12 ///
				${`HC'} ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Very High FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1a_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Not in FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\FHSZ\model_1a_`HC'_`FE'_notFHSZ.png", as(png) replace
			}
		}
	}	

********************************** Model 1b **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 o.FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12 ///
				notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 o.notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12 ///
				io0.FHSZ ${`HC'} ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Very High FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1b_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Not in FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\FHSZ\model_1b_`HC'_`FE'_notFHSZ.png", as(png) replace
			}
		}
	}	


********************************** Model 1c **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 o.FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12 ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				${`HC'} ///
				if HAZ_CODE==0 | HAZ_CODE==3 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Very High FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1c_`HC'_`FE'_`treat'2.png", as(png) replace
				
				coefplot model_1a, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Not in FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\FHSZ\model_1c_`HC'_`FE'_baseline2.png", as(png) replace
			}
		}
	}	

	// ...2 means reg is with "if HAZ_CODE==0 | HAZ_CODE==3"
********************************** Model 1d **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 o.FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12 ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				io0.FHSZ ${`HC'} ///
				if HAZ_CODE==0 | HAZ_CODE==3 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(FHSZ_VH_event_lead12 FHSZ_VH_event_lead11 FHSZ_VH_event_lead10 FHSZ_VH_event_lead9 FHSZ_VH_event_lead8 FHSZ_VH_event_lead7 FHSZ_VH_event_lead6 FHSZ_VH_event_lead5 FHSZ_VH_event_lead4 FHSZ_VH_event_lead3 FHSZ_VH_event_lead2 FHSZ_VH_event_lead1 FHSZ_VH_event_0 FHSZ_VH_event_lag1 FHSZ_VH_event_lag2 FHSZ_VH_event_lag3 FHSZ_VH_event_lag4 FHSZ_VH_event_lag5 FHSZ_VH_event_lag6 FHSZ_VH_event_lag7 FHSZ_VH_event_lag8 FHSZ_VH_event_lag9 FHSZ_VH_event_lag10 FHSZ_VH_event_lag11 FHSZ_VH_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Very High FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1d_`HC'_`FE'_`treat'2.png", as(png) replace
				
				coefplot model_1a, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (Not in FHSZ)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\FHSZ\model_1d_`HC'_`FE'_baseline2.png", as(png) replace
			}
		}
	}

******************************** Model 1e.24 *********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -25 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				${`HC'} ///
				if HAZ_CODE == 0 ///
				& event_sale > -25 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
				
				coefplot (model_1, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(very high FHSZ)) ///
				(model_2, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(not in FHSZ)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices (by fire risk)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(23.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_24m.png", as(png) replace
			}
		}
	}	

******************************** Model 1e.18 *********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -19 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				${`HC'} ///
				if HAZ_CODE == 0 ///
				& event_sale > -19 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
				
				coefplot (model_1, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(very high FHSZ)) ///
				(model_2, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(not in FHSZ)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices (by fire risk)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(17.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_18m.png", as(png) replace
			}
		}
	}
	
		
	
******************************** Model 1e.12 *********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -13 & event_sale < 13 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				${`HC'} ///
				if HAZ_CODE == 0 ///
				& event_sale > -13 & event_sale < 13 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
				
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ)) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices (by fire risk)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_12m.png", as(png) replace
			}
		}
	}

		
	
********************************** Model 2a **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 o.`treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12 ///
				notClose_event_lead12 notClose_event_lead11 notClose_event_lead10 notClose_event_lead9 notClose_event_lead8 notClose_event_lead7 notClose_event_lead6 notClose_event_lead5 notClose_event_lead4 notClose_event_lead3 notClose_event_lead2 o.notClose_event_lead1 notClose_event_0 notClose_event_lag1 notClose_event_lag2 notClose_event_lag3 notClose_event_lag4 notClose_event_lag5 notClose_event_lag6 notClose_event_lag7 notClose_event_lag8 notClose_event_lag9 notClose_event_lag10 notClose_event_lag11 notClose_event_lag12 ///
				${`HC'} ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 `treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (within 2 miles)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2a_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(notClose_event_lead12 notClose_event_lead11 notClose_event_lead10 notClose_event_lead9 notClose_event_lead8 notClose_event_lead7 notClose_event_lead6 notClose_event_lead5 notClose_event_lead4 notClose_event_lead3 notClose_event_lead2 notClose_event_lead1 notClose_event_0 notClose_event_lag1 notClose_event_lag2 notClose_event_lag3 notClose_event_lag4 notClose_event_lag5 notClose_event_lag6 notClose_event_lag7 notClose_event_lag8 notClose_event_lag9 notClose_event_lag10 notClose_event_lag11 notClose_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (5-10 miles away)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\close\model_2a_`HC'_`FE'_notClose.png", as(png) replace
			}
		}
	}		
	
********************************** Model 2b **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 o.`treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12 ///
				notClose_event_lead12 notClose_event_lead11 notClose_event_lead10 notClose_event_lead9 notClose_event_lead8 notClose_event_lead7 notClose_event_lead6 notClose_event_lead5 notClose_event_lead4 notClose_event_lead3 notClose_event_lead2 o.notClose_event_lead1 notClose_event_0 notClose_event_lag1 notClose_event_lag2 notClose_event_lag3 notClose_event_lag4 notClose_event_lag5 notClose_event_lag6 notClose_event_lag7 notClose_event_lag8 notClose_event_lag9 notClose_event_lag10 notClose_event_lag11 notClose_event_lag12 ///
				`treat' ${`HC'} ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 `treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (within 2 miles)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2b_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(notClose_event_lead12 notClose_event_lead11 notClose_event_lead10 notClose_event_lead9 notClose_event_lead8 notClose_event_lead7 notClose_event_lead6 notClose_event_lead5 notClose_event_lead4 notClose_event_lead3 notClose_event_lead2 notClose_event_lead1 notClose_event_0 notClose_event_lag1 notClose_event_lag2 notClose_event_lag3 notClose_event_lag4 notClose_event_lag5 notClose_event_lag6 notClose_event_lag7 notClose_event_lag8 notClose_event_lag9 notClose_event_lag10 notClose_event_lag11 notClose_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (5-10 miles away)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\close\model_2b_`HC'_`FE'_notClose.png", as(png) replace
			}
		}
	}	


********************************** Model 2c **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 o.`treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12 ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				${`HC'} ///
				if dist_miles > 5 | dist_miles < 2 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 `treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (within 2 miles)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2c_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (all transactions)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\close\model_2c_`HC'_`FE'_baseline.png", as(png) replace
			}
		}
	}	

********************************** Model 2d **********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 o.`treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12 ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				`treat' ${`HC'} ///
				if dist_miles > 5 | dist_miles < 2 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1a
		
				coefplot model_1a, keep(`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 `treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (within 2 miles)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2d_`HC'_`FE'_`treat'.png", as(png) replace
				
				coefplot model_1a, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) ///
				vertical title( "{stSerif:{it:Log House Sale Prices Around Fire Event (all transactions)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				ciopts(lcolor(maroon)) mcolor(maroon)

				graph export "${figures}\event_study\close\model_2d_`HC'_`FE'_baseline.png", as(png) replace
			}
		}
	}	
	
******************************** Model 2e.24 *********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -25 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -25 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(within 2 miles)) ///
				(model_2, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(5-10 miles away)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(23.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_24m.png", as(png) replace
			}
		}
	}		
	
****************************** Model 2e.18-24 ********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -19 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -19 & event_sale < 25 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(within 2 miles)) ///
				(model_2, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(5-10 miles away)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(17.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_18m24m.png", as(png) replace
			}
		}
	}			
	
******************************** Model 2e.18 ********************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -19 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -19 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(within 2 miles)) ///
				(model_2, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ) label(5-10 miles away)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(17.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_18m.png", as(png) replace
			}
		}
	}				
	
******************************* Model 2e.12-18 *******************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -13 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -13 & event_sale < 19 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(within 2 miles)) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ) label(5-10 miles away)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_12m18m.png", as(png) replace
			}
		}
	}				
	
********************************* Model 2e.12 *******************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2 {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -13 & event_sale < 13 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -13 & event_sale < 13 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(within 2 miles)) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(5-10 miles away)) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(11.5, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_12m.png", as(png) replace
			}
		}
	}					
	
	
	//Best figures are 1e and 2e. They perfectly show the way that FHSZ and being close are interpreted differently. Close homes seem to get the signal faster than far homes. They react while the fire is going on. After that, they mostly look the same. It looks like close homes maybe start to go back up to baseline? Could this be the asthetic effect? 
	//On the other hand, the FHSZ effect appears on the surface like they weren't affected at all. I believe they face two effects that counteract each other--the asthetic effect and the true risk effect. 
	//Possible explanations:
	//1) Rational risk explanation: FHSZ buyers are rationally updating, realizing that the risk has decreased
	//2) Auction explanation? Winner's curse?
	//3) 
	//NEXT STEP: Expand the post period out further. Try 18 months? See if close and far continue back up to baseline.
	