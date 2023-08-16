* Author: 	Trevor Woolley
* Date:		Aug 16, 2023
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

		
******************************************************************************
							* Quantity regs	
******************************************************************************
*RD regs
******************************************************************************

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
******************************************************************************
* DD regs	(Quantity)
******************************************************************************
	
	* DD post x i.HAZ_CODE
	foreach FE in FIPS city zip {
		use "${data_ztrax}\reg_data_RR_collapsed_`FE'_v2", clear
		* Relabel vars
		label variable log_trans_per_month_FHSZ "log sales per month"
		label variable not_FHSZ_VH "not very-high-FHSZ"
		label variable not_FHSZ "non-FHSZ"
		
		* regs
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post##HAZ_CODE ///
		if event_sale > -13 & event_sale < 13 & event_sale !=0 ///
		, absorb(sale_tm) 
		
		eststo DD_quant_not_FHSZ
		
		xi: reghdfe  log_trans_per_month_FHSZ ///
		post##HAZ_CODE ///
		if event_sale > -13 & event_sale < 13 & event_sale !=0 ///
		, absorb(`FE'_mode sale_tm) cluster(`FE'_mode) 
		
		eststo DD_quant_not_FHSZ_`FE' 
			
		esttab DD_quant_not_FHSZ DD_quant_not_FHSZ_`FE' ///
	using ${tables}\DD\DD_quant_allFHSZ_`FE'.tex, se label replace ///
	drop(_cons)
	}		
		