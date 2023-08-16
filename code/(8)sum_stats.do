* Author: 	Trevor Woolley
* Date:		Feb 1, 2022
* Project:	Fire Risk


********************************************************************************
//ssc install tabout
ssc install estout
ssc install esttab

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output"
global tables = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\tables"

********************************************************************************
* House characteristics
global HC2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond"

use "${data_ztrax}\reg_data_RR_event_study_v1", clear
********************************************************************************

	* Regression restrictions
	keep if fire_num_trans > 1000
	keep if event_sale > -13 & event_sale < 13 & event_sale !=0
	
	* Identify unique transactions
	by TransId , sort: gen nvals = _n == 1
	keep if nvals == 1
	
	* Create dummy for medium and high FHSZ
	gen FHSZ_MH = 0
	replace FHSZ_MH = 1 if HAZ_CODE==1 | HAZ_CODE==2
	gen FHSZ2 = 0
	replace FHSZ2 = 1 if HAZ_CODE==1 | HAZ_CODE==2
	replace FHSZ2 = 2 if HAZ_CODE==3
	
	* label variables
	label variable log_SalesPriceAmount "log(sales price)"
	label variable SalesPriceAmount "sales price"
	label variable LotSizeSquareFeet "lot size (sq.ft)"
	label variable YearBuilt "year built"
	label variable TotalBedrooms "\# bedrooms"
	label variable TotalCalculatedBathCount "\# baths"
	label variable build_quality "building quality"
	label variable NoOfStories  "\# stories"
	
	* label values
	label define fhsz 0 "not VH-FHSZ" 1 "VH-FHSZ"
	label values FHSZ_VH fhsz
	label define fhsz2  0 "non-FHSZ" 1 "M- or H-FHSZ" 2 "VH-FHSZ"
	label values FHSZ2 fhsz2
	label define fhsz3  1 "M- or H-FHSZ" 0 "not M- or H-FHSZ"
	label values FHSZ_MH fhsz3
	label define near 0 "2-10 miles away" 1 "within 2 miles"
	label values close_2 near
	label define post_ 0 "pre" 1 "post"
	label values post_events post_
	
	
	
	foreach treat in FHSZ2 {
		estpost tabstat log_SalesPriceAmount SalesPriceAmount LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount NoOfStories build_quality  ///
		if heating !=. & aircond !=. , by(`treat') ///
		statistics(mean sd count) columns(statistics) listwise
	
		eststo sum_`treat'
	
		esttab sum_`treat' using "${tables}\sum\sum_`treat'.tex", ///
		main(mean) aux(sd) nostar unstack ///
		nonote nomtitle nonumber varlabels(`e(labels)') label ///
		replace
	}
	// Bc esttab doesn't report the number of observations in each group, I added that by hand
	
	// Two house charateristics that are missing from the summary stats but used in the regressions are airconditioning and heating types. build_quality is a number 1-6 and is a grade of the building structure. 
	
	* Number of unique transactions with complete house char.
	count if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_events == 0 ///
	& HAZ_CODE == 0
	
	count if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_not_FHSZ_close_2 !=. ///
	& HAZ_CODE >0
	
	count if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_FHSZ_VH_close_2 !=. ///
	& close_2 == 1
	
	count if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_FHSZ_VH_close_2 !=. ///
	& close_5 == 0
	
	* sum details of unique transactions with complete house char.
	sum SalesPriceAmount if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_FHSZ_VH_close_2 !=. ///
	& HAZ_CODE == 0, d
	
	sum SalesPriceAmount if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_FHSZ_VH_close_2 !=. ///
	& close_2==1, d
	
	sum SalesPriceAmount if SalesPriceAmount!=. & LotSizeSquareFeet !=. & YearBuilt !=. & TotalBedrooms !=. & TotalCalculatedBathCount !=. & NoOfStories !=. & build_quality !=. & heating !=. & aircond !=. & post_FHSZ_VH_close_2 !=. ///
	& close_5==0, d
	
	