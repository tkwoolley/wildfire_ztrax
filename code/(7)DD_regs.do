* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk

******************************************************************************
//ssc install tabout

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global figures = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\figures"
global tables = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\tables"

********************************* HOUSE CHAR ********************************
	 * Three levels of housing char from most obs to fewest
	 global HC0 "" 
	 global HC1 "LotSizeSquareFeet YearBuilt TotalBedrooms  TotalCalculatedBathCount i.build_quality"
	 global HC2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount build_quality NoOfStories i.heating i.aircond"
	 global HC3 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond FireplaceNumber i.bath_code TotalRooms"

******************************************************************************
* DDD - FHSZ x distance treatment
******************************************************************************
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

gen post_SRA_city = 0
replace post_SRA_city = 1 if post_events == 1 & SRA_city == 1

	eststo clear
******************************************************************************
	* DDD by FHSZ
	foreach treat1 in FHSZ_VH not_FHSZ {	
		foreach treat2 in close_2 {
			foreach HC in HC2 {
				foreach FE in FIPS {
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_events `treat2' post_`treat2' ///
					post_`treat1'_`treat2' post_`treat1' ///
					 `treat1' `treat1'_`treat2'  ///
					${`HC'} i.FID ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DDD_`treat1'_`HC'_`FE' 
				}
			}
		}
	}
	
	esttab DDD_FHSZ_VH_HC3_FIPS DDD_FHSZ_H_HC3_FIPS DDD_FHSZ_HC3_FIPS ///
	using ${tables}\DD\DDD_HC2_FID.pdf, se label replace ///
	title(Triple Difference Estimates\label{tabl}) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond *FID TotalRooms FireplaceNumber *bath_code _cons )

	
	// Current theory is that "post_close" effects are due to scenery changes and post_FHSZ are due to decreased risk
	// The triple diff (I think) is essentially figuring out which effect is stronger for the close x FHSZ homes. 
	
***************************** DD WITH SRA_city ***************************
	* DDD post x SRA_city by HC
	eststo clear
	foreach treat1 in SRA_city {	
		foreach HC in HC0 HC2 {
			foreach FE in FIPS {
				eststo: reghdfe  log_SalesPriceAmount_HPI ///
				post_`treat1' `treat1'  ///
				post_events ///
				post_close_2 close_2 ///
				${`HC'} i.FID ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				& not_FHSZ ///
				, absorb(`FE' sale_tm) cluster(`FE')
				
				eststo DD_`treat1'_`HC'_`FE' 
			}
		}
	}
	
	esttab DD_SRA_city_HC0_FIPS DD_SRA_city_HC2_FIPS ///
	using ${tables}\DD\DD_SRA_notFHSZ_FID.tex, se label replace ///
	title(Triple Difference Estimates\label{tabl}) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond *FID _cons)
	
************************** Simply "post" for each FHSZ ***********************
	* Post by FHSZ
	egen zip = group(PropertyZip)
	
	eststo clear
	foreach treat1 in post {	
		foreach HC in HC0 HC2 {
			foreach FE in FIPS city zip {
				foreach fhsz in not_FHSZ FHSZ_VH FHSZ_H FHSZ_M {
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_events ///
					post_close_2 close_2 ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 & event_sale !=0 ///
					& fire_num_trans > 1000 ///
					& `fhsz' ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo `treat1'_`fhsz'_`HC'_`FE' 
				}
				if "`HC'" == "HC0" {
					esttab `treat'_not_FHSZ_`HC'_`FE' `treat'_FHSZ_VH_`HC'_`FE' `treat'_FHSZ_H_`HC'_`FE' `treat'_FHSZ_M_`HC'_`FE' ///
					using ${tables}\DD\post_byFHSZ_close_`HC'_`FE'.tex, se label replace ///
					title(Triple Difference Estimates\label{tabl}) ///
					star(* 0.10 ** 0.05 *** 0.01)
				}
				else {
					esttab `treat'_not_FHSZ_`HC'_`FE' `treat'_FHSZ_VH_`HC'_`FE' post_FHSZ_H_`HC'_`FE' `treat'_FHSZ_M_`HC'_`FE' ///
					using ${tables}\DD\post_byFHSZ_close_`HC'_`FE'.tex, se label replace ///
					title(Triple Difference Estimates\label{tabl}) ///
					star(* 0.10 ** 0.05 *** 0.01) ///
					drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond _cons)
				}
			}
		}	
	}	
	
************************** DD post x i.HAZ_CODE ***********************
	* DD by FHSZ	
	eststo clear
	foreach treat1 in DD {	
		foreach HC in HC0 HC2 {
			foreach FE in FIPS city zip {
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_events##HAZ_CODE ///
					post_close_2 close_2 ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 & event_sale !=0 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo `treat1'_byFHSZ_`HC'_`FE' 
				}
			}
		}
		
		esttab DD_byFHSZ_HC0_FIPS DD_byFHSZ_HC0_city DD_byFHSZ_HC0_zip ///
		using ${tables}\DD\DD_byFHSZ_close_HC0_byFE.tex, se label replace ///
		title(Triple Difference Estimates\label{tabl}) ///
		star(* 0.10 ** 0.05 *** 0.01)
					
		esttab DD_byFHSZ_HC2_FIPS DD_byFHSZ_HC2_city DD_byFHSZ_HC2_zip ///
		using ${tables}\DD\DD_byFHSZ_close_HC2_byFE.tex, se label replace ///
		title(Triple Difference Estimates\label{tabl}) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond _cons)			
			
***************************** DD *****************************	
	* DD not_FHSZ by HC
	foreach treat1 in not_FHSZ {	
		foreach treat2 in close_2 {
			foreach HC in HC0 HC2 {
				foreach FE in FIPS {
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2' ///
					post_events ///
					${`HC'} i.FID ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD_`treat1'_`HC'_`FE' 
				}
			}
		}
	}
	
	esttab DD_not_FHSZ_HC0_FIPS DD_not_FHSZ_HC2_FIPS ///
	using ${tables}\DD\DD_not_FHSZ_byHC_FID.tex, se label replace ///
	title(Triple Difference Estimates\label{tabl}) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond *FID _cons)
	
	* DD not_FHSZ_VH in (medium or high FHSZ) v. not in FHSZ
	foreach treat1 in not_FHSZ_VH {	
		foreach treat2 in close_2 {
			foreach HC in HC2 {
				foreach FE in FIPS {
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_not_FHSZ not_FHSZ ///
					post_`treat1' `treat1'  ///
					post_`treat2' `treat2' ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD0_`treat1'_`HC'_`FE' 
					
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1'  ///
					post_`treat2' `treat2' ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					& HAZ_CODE !=1 & HAZ_CODE!=2  ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD1_`treat1'_`HC'_`FE' 
					
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2' ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					& HAZ_CODE !=0 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD2_`treat1'_`HC'_`FE' 
				}
			}
		}
	}
	
	esttab DD1_not_FHSZ_VH_HC2_FIPS DD2_not_FHSZ_VH_HC2_FIPS ///
	using ${tables}\DD\DD_not_FHSZ_VH_byHC.tex, se label replace ///
	title(Triple Difference Estimates\label{tabl}) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond _cons)
	
	* DD not_FHSZ and HC2 w/ different geo FE
	foreach treat1 in not_FHSZ {	
		foreach treat2 in close_2 {
			foreach HC in HC2 {
				foreach FE in FIPS {					
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2'  ///
					post_events ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(sale_tm)
					
					eststo DD4_`treat1'_`HC'
					
					eststo DD4_`treat1'_`HC'
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2'  ///
					post_events ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(FID sale_tm) cluster(FID)
					
					eststo DD4_`treat1'_`HC'_FID
					
					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2'  ///
					post_events ///
					${`HC'} ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD4_`treat1'_`HC'_`FE'

					eststo: reghdfe  log_SalesPriceAmount_HPI ///
					post_`treat1' `treat1' ///
					post_`treat2' `treat2'  ///
					post_events ///
					${`HC'} i.FID ///
					if event_sale > -13 & event_sale < 13 ///
					& fire_num_trans > 1000 ///
					, absorb(`FE' sale_tm) cluster(`FE')
					
					eststo DD4_`treat1'_`HC'_FID`FE'
					
				}
			}
		}
	}
	
	esttab DD4_not_FHSZ_HC2 DD4_not_FHSZ_HC2_FIPS DD4_not_FHSZ_HC2_FID DD4_not_FHSZ_HC2_FIDFIPS   ///
	using ${tables}\DD\DD_not_FHSZ_byFE.tex, se label replace ///
	title(Triple Difference Estimates\label{tabl}) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	drop(LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount *build_quality NoOfStories *heating *aircond *FID _cons)
	

	******************************************************************************
							* House char regs	
******************************************************************************
*RD regs
******************************************************************************
	
	* All
	foreach hc in LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount build_quality NoOfStories {
		foreach FE in FIPS {
			xi: reghdfe  `hc' ///
			post_events ///
			if event_sale > -13 & event_sale < 13 ///
			& fire_num_trans > 1000 ///
			, absorb(`FE' sale_tm) cluster(`FE') 
			
			eststo RD_HC_all_`FE' 
		}	
	}
	//Houses sold after a fire event are signifiantly lower quality. Bedrooms decreased, baths decreased, build_quality increased (so decreased), and number of stories decreased
	//Note that for build_quality, 1 is the best and 6 is worst
	
	* FHSZ_VH or close_2
	foreach treat in FHSZ_VH close_2 {
		foreach hc in LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount build_quality NoOfStories {
			foreach FE in FIPS {
				disp "*** `treat' ***"
				xi: reghdfe  `hc' ///
				post_events ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				& `treat' == 1 ///
				, absorb(`FE' sale_tm) cluster(`FE') 
				
				eststo RD_HC_`treat'_`FE' 
			}	
		}
	}
	// For FHSZ_VH: Number of Stories decreases and number of baths decreases. The others don't change
	// For close_2: Total bedrooms decreases and baths seem to increase. The others don't change.
	// Maybe try making the build_quality into dummies?
	
******************************************************************************
*DD regs
******************************************************************************
	* FHSZ_VH or close_2
	foreach treat in FHSZ_VH close_2 {
		foreach hc in LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount build_quality NoOfStories {
			foreach FE in FIPS {
				disp "*** `treat' ***"
				xi: reghdfe  `hc' ///
				post_`treat' `treat' post_events ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE') 
				
				eststo DD_HC_`treat'_`FE' 
			}	
		}
	}
	//FHSZ_VH and close_2 seem to have the same trend as normal. There's nothing particularly special about them. Still, the same trend: Overall, lower quality homes sell after fire. Why? Who are these people? 
	
******************************************************************************
								* Quality regs
*****************************************************************************
use "${data_ztrax}\reg_data_RR_event_study_v1", clear

	* label vars
	label variable log_SalesPriceAmount_HPI "log sale price"
	label variable SalesPriceAmount "sale price"
	label variable LotSizeSquareFeet "lot size (sq.ft)"
	label variable YearBuilt "year built"
	label variable TotalBedrooms "\# bedrooms"
	label variable TotalCalculatedBathCount "\# baths"
	label variable build_quality "building quality"
	label variable NoOfStories  "\# stories"
	label variable HAZ_CODE "FHSZ level"

	*Predict based on event time -1 
	foreach FE in FIPS {	
		reghdfe log_SalesPriceAmount_HPI ${HC2} HAZ_CODE ///
		if event_sale == -1 ///
		& fire_num_trans > 1000 ///
		, absorb(`FE' sale_tm) cluster(`FE')
		
		eststo DD_hedonic
		//predict quality
	}
	
	esttab DD_hedonic ///
	using ${tables}\DD\predictive_hedonic.tex, se label replace ///
	nonum drop(*heating *aircond _cons) 

******************************************************************************
*Use predicted quality to see how quality changed after fire
*****************************************************************************
	* Relabel vars
	label variable quality "predicted log sale price"
	
	*All 
	foreach FE in FIPS {	
		reghdfe quality post_events ///
		if event_sale > -13 & event_sale < 13 ///
		& fire_num_trans > 1000 ///
		, absorb(`FE' sale_tm) cluster(`FE')
		
		eststo RD_quality_all
	}

	* DD FHSZ_VH & close_2
		foreach outcome in quality {
			foreach FE in FIPS {
				disp "*** `treat' ***"
				xi: reg  `outcome' ///
				post_FHSZ_VH FHSZ_VH ///
				post_close_2 close_2 post_events ///
				if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				,  cluster(`FE') 
				
				eststo DD_quality
			}	
		}

	
	esttab DD_quality ///
	using ${tables}\DD\DD_quality.tex, se label replace ///
	nonum drop( _cons) 
	
******************************************************************************
							* Quantity regs	
******************************************************************************
*RD regs
******************************************************************************
use "${data_ztrax}\reg_data_RR_collapsed", clear
	* All
	foreach FE in FIPS_mode {
		xi: reghdfe  log_trans_per_month_all ///
		post ///
		if event_sale > -13 & event_sale < 13 ///
		, absorb(`FE' sale_tm) cluster(`FE') 
		
		eststo RD_quant_all_`FE' 
	}	

	* RD by FHSZ
	foreach FE2 in FIPS city zip {
		 use "${data_ztrax}\reg_data_RR_collapsed_`FE2'_v2", clear	
		drop not_FHSZ FHSZ_VH
		gen not_FHSZ = 0
		replace not_FHSZ = 1 if HAZ_CODE == 0
		gen FHSZ_M = 0
		replace FHSZ_M = 1 if HAZ_CODE == 1
		gen FHSZ_H = 0
		replace FHSZ_H = 1 if HAZ_CODE == 2
		gen FHSZ_VH = 0
		replace FHSZ_VH = 1 if HAZ_CODE == 3
		
		* by FHSZ
		eststo clear
		foreach treat in not_FHSZ FHSZ_M FHSZ_H FHSZ_VH {
			foreach FE in `FE2'_mode  {
				xi: reghdfe  log_trans_per_month_FHSZ ///
				post ///
				if event_sale > -13 & event_sale < 13 & event_sale !=0 ///
				& `treat' == 1 ///
				, absorb(`FE' sale_tm) cluster(`FE') 
				
				eststo RD_quant_`treat'_`FE' 
			}	
		}
	
	esttab RD_quant_not_FHSZ_`FE2'_mode RD_quant_FHSZ_M_`FE2'_mode RD_quant_FHSZ_H_`FE2'_mode RD_quant_FHSZ_VH_`FE2'_mode ///
	using ${tables}\DD\RD_quant_byFHSZ_`FE2'.tex, se label replace	
	}
	
	* Close 2 miles
	foreach treat in close_2 {
		foreach FE in FIPS_mode {
			xi: reghdfe  log_trans_per_month_close2 ///
			post ///
			if event_sale > -13 & event_sale < 13 ///
			& `treat' == 1 ///
			, absorb(`FE' sale_tm) cluster(`FE') 
			
			eststo RD_quant_`treat'_`FE' 
		}	
	}
	
	esttab RD_quant_all_FIPS_mode RD_quant_FHSZ_VH_FIPS_mode RD_quant_close_2_FIPS_mode ///
	using ${tables}\DD\RD_quant_FHSZ_VH_FIPS.tex, se label replace

******************************************************************************
* DD regs	(Quantity)
******************************************************************************
	
	* DD FHSZ v. not
	foreach FE in FIPS {
		use "${data_ztrax}\reg_data_RR_collapsed_`FE'_v2", clear
		* Relabel vars
		label variable log_trans_per_month_FHSZ "log sales per month"
		label variable not_FHSZ_VH "not very-high-FHSZ"
		label variable not_FHSZ "non-FHSZ"
		
		* regs
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post_not_FHSZ not_FHSZ post ///
		if event_sale > -13 & event_sale < 13 ///
		, absorb(sale_tm) 
		
		eststo DD_quant_not_FHSZ
		
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post_not_FHSZ not_FHSZ post ///
		if event_sale > -13 & event_sale < 13 ///
		, absorb(`FE'_mode sale_tm) cluster(`FE'_mode) 
		
		eststo DD_quant_not_FHSZ_`FE' 
			
		esttab DD_quant_not_FHSZ DD_quant_not_FHSZ_`FE' ///
	using ${tables}\DD\DD_quant_`FE'.tex, se label replace ///
	drop(_cons)
	}
	
	* DD post x i.HAZ_CODE
	foreach FE in FIPS city zip{
		use "${data_ztrax}\reg_data_RR_collapsed_`FE'_v2", clear
		* Relabel vars
		label variable log_trans_per_month_FHSZ "log sales per month"
		label variable not_FHSZ_VH "not very-high-FHSZ"
		label variable not_FHSZ "non-FHSZ"
		
		* regs
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post##HAZ_CODE ///
		if event_sale > -13 & event_sale < 13 ///
		, absorb(sale_tm) 
		
		eststo DD_quant_not_FHSZ
		
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post##HAZ_CODE ///
		if event_sale > -13 & event_sale < 13 ///
		, absorb(`FE'_mode sale_tm) cluster(`FE'_mode) 
		
		eststo DD_quant_not_FHSZ_`FE' 
			
		esttab DD_quant_not_FHSZ DD_quant_not_FHSZ_`FE' ///
	using ${tables}\DD\DD_quant_allFHSZ_`FE'.tex, se label replace ///
	drop(_cons)
	}
	
******************************************************************************
							* Unoccupied regs
******************************************************************************
	* DD FHSZ
	foreach treat in FHSZ_VH {
		foreach FE in FIPS_mode {
			xi: reghdfe  unoccupied ///
			post_`treat' `treat' post ///
			if event_sale > -13 & event_sale < 13 ///
			, absorb(`FE' sale_tm) cluster(`FE') 
			
			eststo DD_unoccupied_`treat' 
		}
	}
	//It appears that unoccupied sales do increase a little after a fire in very high FHSZ but only by 4 percentage points
	
	* DD close_2
	foreach treat in close_2 {
		foreach FE in FIPS_mode {
			xi: reghdfe  unoccupied ///
			post_`treat' `treat' post ///
			if event_sale > -13 & event_sale < 13 ///
			, absorb(`FE' sale_tm) cluster(`FE') 
			
			eststo DD_unoccupied_`treat'
		}
	}
	
	esttab DD_unoccupied_FHSZ_VH DD_unoccupied_close_2 ///
	using ${tables}\DD\DD_unoccupied_FHSZ_VH_FIPS.tex, se label replace 
	
	
	
	