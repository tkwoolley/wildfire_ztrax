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


********************************* HOUSE CHAR ********************************
	 * Three levels of housing char from most obs to fewest
	 global HC0 ""
	 global HC1 "LotSizeSquareFeet YearBuilt TotalBedrooms  TotalCalculatedBathCount i.build_quality"
	 global HC2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond"
	 global HC3 "LotSizeSquareFeet YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount i.build_quality i.heating i.aircond FireplaceNumber i.bath_code"
	 
******************************** EVENT STUDY *********************************
	// Model 1:	event study with FHSZ interaction on treatment
	// Model 2: event study with distance interaction on treatment
	//The right-most number is the number of lead/lag events in regs
use "${data_ztrax}\reg_data_RR_event_study_v1", clear

* Few data adjustments
drop FHSZ_H
gen FHSZ_M = 0
replace FHSZ_M = 1 if HAZ_CODE==1
bysort PropertyCity: egen FHSZ_M_city_count = sum(FHSZ_M)
gen FHSZ_H = 0
replace FHSZ_H = 1 if HAZ_CODE==2
bysort PropertyCity: egen FHSZ_H_city_count = sum(FHSZ_H)

gen SRA_city = 0
replace SRA_city = 1 if (FHSZ_M_city_count >0 & FHSZ_M_city_count!=.) | (FHSZ_H_city_count >0 & FHSZ_H_city_count!=.)


*****************************************************************************
******************************** Model 1e.12 *********************************
	foreach HC in HC0 HC2 {
		foreach FE in FIPS { //PropertyCity PropertyZip 
			foreach treat in FHSZ {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE == 3 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE == 0 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE ==1 | HAZ_CODE==2 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_3
				
				
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ) omitted) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ) omitted) ///
				(model_3, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(medium- or high-FHSZ) omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_12m_allFHSZ.png", as(png) replace
			}
		}
	}
	
* non-FHSZ v. any FHSZ
	foreach HC in HC0 HC2 {
		foreach FE in FIPS {
			foreach treat in FHSZ_VH {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE>0 & HAZ_CODE !=. ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE == 0 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2

				
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(any FHSZ) omitted) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ) omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_12m_anyFHSZ_close2.png", as(png) replace
			}
		}
	}
	
* non-FHSZ in SRA v. not in SRA

	foreach HC in HC0 HC2 {
		foreach FE in FIPS FID {
			foreach treat in SRA {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE==0 & SRA_city ==0 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				post_close_2 close_2 ///
				${`HC'} ///
				if HAZ_CODE == 0 & SRA_city ==1 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2

				
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(SRA city) omitted) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not SRA city) omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_12m_`treat'_close2.png", as(png) replace
			}
		}
	}	
******************************************************************************
********************************* Model 2e.12 *******************************
	foreach HC in HC0 HC2 {
		foreach FE in FIPS {
			foreach treat in close_2  {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				 ${`HC'} ///
				if `treat' == 1 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
				
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				 ${`HC'} ///
				if dist_miles > 5 ///
				& event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_2
		
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(within 2 miles) omitted) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(5-10 miles away) omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
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
	//3) Insurance? 
	//4) People moving away? Probably not because I would expect more people to move away the closer they are.
	//NEXT STEP: Expand the post period out further. Try 18 months? See if close and far continue back up to baseline.

****************************************************************************
* Dynamic Differences	
//3a DDD
//3b DD 
********************************* Model 3a.12 *******************************
	foreach HC in HC0 HC2 {
		foreach FE in FIPS {
			foreach treat in close_2  {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				FHSZ_VH_close_2_event_lead12 FHSZ_VH_close_2_event_lead11 FHSZ_VH_close_2_event_lead10 FHSZ_VH_close_2_event_lead9 FHSZ_VH_close_2_event_lead8 FHSZ_VH_close_2_event_lead7 FHSZ_VH_close_2_event_lead6 FHSZ_VH_close_2_event_lead5 FHSZ_VH_close_2_event_lead4 FHSZ_VH_close_2_event_lead3 FHSZ_VH_close_2_event_lead2 o.FHSZ_VH_close_2_event_lead1 FHSZ_VH_close_2_event_0 FHSZ_VH_close_2_event_lag1 FHSZ_VH_close_2_event_lag2 FHSZ_VH_close_2_event_lag3 FHSZ_VH_close_2_event_lag4 FHSZ_VH_close_2_event_lag5 FHSZ_VH_close_2_event_lag6 FHSZ_VH_close_2_event_lag7 FHSZ_VH_close_2_event_lag8 FHSZ_VH_close_2_event_lag9 FHSZ_VH_close_2_event_lag10 FHSZ_VH_close_2_event_lag11 FHSZ_VH_close_2_event_lag12 ///
				post_events `treat' post_`treat' ///
				post_FHSZ_VH FHSZ_VH FHSZ_VH_`treat'  ///
				${`HC'} i.FID ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
		
				estimates store model_1
		
				coefplot (model_1, keep(FHSZ_VH_close_2_event_lead12 FHSZ_VH_close_2_event_lead11 FHSZ_VH_close_2_event_lead10 FHSZ_VH_close_2_event_lead9 FHSZ_VH_close_2_event_lead8 FHSZ_VH_close_2_event_lead7 FHSZ_VH_close_2_event_lead6 FHSZ_VH_close_2_event_lead5 FHSZ_VH_close_2_event_lead4 FHSZ_VH_close_2_event_lead3 FHSZ_VH_close_2_event_lead2 FHSZ_VH_close_2_event_lead1 FHSZ_VH_close_2_event_0 FHSZ_VH_close_2_event_lag1 FHSZ_VH_close_2_event_lag2 FHSZ_VH_close_2_event_lag3 FHSZ_VH_close_2_event_lag4 FHSZ_VH_close_2_event_lag5 FHSZ_VH_close_2_event_lag6 FHSZ_VH_close_2_event_lag7 FHSZ_VH_close_2_event_lag8 FHSZ_VH_close_2_event_lag9 FHSZ_VH_close_2_event_lag10 FHSZ_VH_close_2_event_lag11 FHSZ_VH_close_2_event_lag12) label(Triple Differernce Effect) omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\DDD\model_3a_`HC'_`FE'_`treat'_12m.png", as(png) replace
			}
		}
	}			

*****************************************************************************
// DD Graphs
********************************* Model 3b.12 *******************************
	foreach HC in HC2 {
		foreach FE in FIPS {
			foreach treat in close_2  {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 o.notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12 ///
				not_FHSZ  ///
				post_close_2 close_2 ///
				${`HC'} i.FID ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE') base
		
				estimates store model_1
		
				coefplot model_1, keep(notFHSZ_event_lead12 notFHSZ_event_lead11 notFHSZ_event_lead10 notFHSZ_event_lead9 notFHSZ_event_lead8 notFHSZ_event_lead7 notFHSZ_event_lead6 notFHSZ_event_lead5 notFHSZ_event_lead4 notFHSZ_event_lead3 notFHSZ_event_lead2 notFHSZ_event_lead1 notFHSZ_event_0 notFHSZ_event_lag1 notFHSZ_event_lag2 notFHSZ_event_lag3 notFHSZ_event_lag4 notFHSZ_event_lag5 notFHSZ_event_lag6 notFHSZ_event_lag7 notFHSZ_event_lag8 notFHSZ_event_lag9 notFHSZ_event_lag10 notFHSZ_event_lag11 notFHSZ_event_lag12) label(Triple Differernce Effect) base omitted ///
				vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\DDD\model_3b_`HC'_`FE'_notFHSZ_12m_wFID.png", as(png) replace
			}
		}
	}	
	
******************************************************************************	
********************************* Model 3c.12 *******************************
	foreach HC in HC0 HC2 {
		foreach FE in FIPS {
			foreach treat in close_2  {
				xtset sale_tm
				xi: reghdfe  log_SalesPriceAmount_HPI ///
				`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 o.`treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12 ///
				post_events `treat' ///
				${`HC'} i.FID ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE') base
		
				estimates store model_1
		
				coefplot model_1, keep(`treat'_event_lead12 `treat'_event_lead11 `treat'_event_lead10 `treat'_event_lead9 `treat'_event_lead8 `treat'_event_lead7 `treat'_event_lead6 `treat'_event_lead5 `treat'_event_lead4 `treat'_event_lead3 `treat'_event_lead2 `treat'_event_lead1 `treat'_event_0 `treat'_event_lag1 `treat'_event_lag2 `treat'_event_lag3 `treat'_event_lag4 `treat'_event_lag5 `treat'_event_lag6 `treat'_event_lag7 `treat'_event_lag8 `treat'_event_lag9 `treat'_event_lag10 `treat'_event_lag11 `treat'_event_lag12) label(Triple Differernce Effect) base omitted ///
				vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\DDD\model_3c_`HC'_`FE'_`treat'_12m.png", as(png) replace
			}
		}
	}	
	
	// ..._bothDD means includes both post_FHSZ_VH and post_close_2 (as well as both FHSZ_VH and close_2) in regression
	
******************************************************************************
								* Quality Plots
******************************************************************************
use "${data_ztrax}\reg_data_RR_event_study_v0", clear

	*Predict based on event time -1 
	foreach FE in FIPS {	
		reghdfe log_SalesPriceAmount_HPI ${HC2} HAZ_CODE ///
		if event_sale == -1 ///
		& fire_num_trans > 1000 ///
		, absorb(`FE' sale_tm) cluster(`FE')
		
		predict quality
	}

	foreach treat in close_2 {
		foreach outcome in quality {
			foreach FE in FIPS {
				xtset sale_tm
				xi: reg  `outcome' ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				if event_sale > -13 & event_sale < 13 ///
				& `treat' == 1 ///
				& fire_num_trans > 1000 ///
				//, absorb(`FE' sale_tm) cluster(`FE') base
		
				estimates store model_1
				
				xi: reg  `outcome' ///
				event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
				if event_sale > -13 & event_sale < 13 ///
				& `treat' == 0 ///
				& fire_num_trans > 1000 ///
				//, absorb(`FE' sale_tm) cluster(`FE') base
		
				estimates store model_2
		
				if "`treat'" == "FHSZ_VH" {
					local treat_label = "very high FHSZ"
					local not_treat_label = "not in very high FHSZ"
				}
				else if "`treat'" == "close_2" {
					local treat_label = "within 2 miles"
					local not_treat_label = "2-10 miles away"
				}
				
				coefplot (model_1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(`treat_label') base omitted) ///
				(model_2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(`not_treat_label') base omitted) ///
				, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\quality\\`outcome'_`FE'_`treat'_12m.png", as(png) replace
			}
		}
	}		
	
******************************************************************************
							* Quantity plots	
******************************************************************************
* All transactions
use "${data_ztrax}\reg_data_RR_collapsed", clear
******************************************************************************
	xi: reghdfe  log_trans_per_month_all ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode)

	estimates store model_all

	coefplot (model_all, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_all.png", as(png) replace
	
**************************************************************************
* Plots by FE
foreach FE in PropertyCity PropertyZip FIPS {
******************************************************************************
* Very high FHSZ v. not in FHSZ
use "${data_ztrax}\reg_data_RR_collapsed_`FE'_v2", clear
******************************************************************************
	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 3 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode )

	estimates store model_fhsz3

	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 0 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode)

	estimates store model_fhsz0
	
	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 1 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode)

	estimates store model_fhsz1
	
	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 2 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode)

	estimates store model_fhsz2

	coefplot (model_fhsz3, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ) omitted) ///
	(model_fhsz0, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ) omitted) ///
	(model_fhsz1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(medium FHSZ) omitted) ///
	(model_fhsz2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(high FHSZ) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_allFHSZ_`FE'.png", as(png) replace
	
* non-FHSZ v. any FHSZ
	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE ==3 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode )

	estimates store model_fhsz3

	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 0 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode)

	estimates store model_fhsz0
	
	xi: reghdfe  log_trans_per_month_FHSZ ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE !=0 & HAZ_CODE!=3 ///
	, absorb(`FE'_mode sale_tm) cluster(`FE'_mode)

	estimates store model_fhsz1
	

	coefplot (model_fhsz3, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ) omitted) ///
	(model_fhsz0, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ) omitted) ///
	(model_fhsz1, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(medium- or high-FHSZ) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_anyFHSZ_`FE'.png", as(png) replace
}	
				
******************************************************************************
* Close (2 mils) v. not close (5-10 miles)
******************************************************************************
	xi: reghdfe  log_trans_per_month_close2 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& close_2 == 1 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )

	estimates store model_close2

	xi: reghdfe  log_trans_per_month_close5 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& close_5 == 0 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )
	
	estimates store model_close5

	coefplot (model_close2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(within 2 miles) omitted) ///
	(model_close5, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(5-10 miles away) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_close.png", as(png) replace				
	
	
******************************************************************************
* very high FHSZ & Close (2 mils) v. very high FHSZ & not close (5-10 miles)
******************************************************************************
	xi: reghdfe  log_trans_per_month_FHSZclose2 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 3 & close_2 == 1 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )

	estimates store model_close2

	xi: reghdfe  log_trans_per_month_FHSZclose5 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& close_5 == 0 & HAZ_CODE == 3  ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )

	estimates store model_close5

	coefplot (model_close2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ & within 2 miles) omitted) ///
	(model_close5, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ & 5-10 miles away) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_FHSZclose.png", as(png) replace	
	
******************************************************************************
* very high FHSZ & Close (2 mils) v. not in FHSZ & close (2 miles)
******************************************************************************
	xi: reghdfe  log_trans_per_month_FHSZclose2 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 3 & close_2 == 1 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )

	estimates store model_close2

	xi: reghdfe  log_trans_per_month_FHSZclose2 ///
	event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 ///
	if event_sale > -13 & event_sale < 13 ///
	& HAZ_CODE == 0 & close_2 == 1 ///
	, absorb(FIPS_mode sale_tm) cluster(FIPS_mode )

	estimates store model_close5

	coefplot (model_close2, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(very high FHSZ & within 2 miles) omitted) ///
	(model_close5, keep(event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12) label(not in FHSZ & within 2 miles) omitted) ///
	, vertical xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
	xline(12, lwidth(thin) lpattern(dash) lcolor(black)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin))
	//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

	graph export "${figures}\event_study\quantity\quantity_12m_FHSZclose2.png", as(png) replace			
	