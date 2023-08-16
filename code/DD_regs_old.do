* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk

********************************************************************************
//ssc install tabout

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"

******************************* Edit Variables *******************************
	use "${data_ztrax}\reg_data_RR", clear
	
	* Make PropertyCity into indicator
	egen city = group(PropertyCity)
	egen my = group(sale_tm)
	egen event = group(event_sale) if event_sale > -24 & event_sale < 24
	// this makes event time 0 (during fire) into event == 24
	egen fire_event = group(NEAR_FID)
	
	* Make house char factor vars
	egen occupy = group(OccupancyStatusStndCode)
	egen build_quality = group(BuildingQualityStndCode)
	egen bath_code = group(BathSourceStndCode) 
	egen heating = group(HeatingTypeorSystemStndCode)
	egen aircond = group(AirConditioningTypeorSystemStndC)
	
	* seasonal controls
	gen month = month(sale_date)
	gen spring = 0
	replace spring = 1 if month == 3 | month == 4 | month == 5
	gen summer = 0
	replace summer = 1 if month == 6 | month == 7 | month == 8
	gen fall = 0
	replace fall = 1 if month == 9 | month == 10 | month == 11
	
	* Treatment period
	gen treat_period = 0
	replace treat_period = 1 if event_sale == 0 | event_sale == 1 | event_sale == 2
	
	gen treat_m = 0
	forvalues i = 1/7 {
		local j = `i' - 1
		replace treat_m = `i' if event_sale == `j'
	}
	
	* FHSZ
	gen FHSZ = 0
	replace FHSZ = 1 if HAZ_CODE != .
	gen FHSZ_H = 0
	replace FHSZ_H = 1 if HAZ_CODE > 1 & HAZ_CODE != .
	gen FHSZ_VH = 0
	replace FHSZ_VH = 1 if  HAZ_CODE > 2 & HAZ_CODE != .
	
	gen treat_FHSZ = 0
	replace treat_FHSZ = treat_period if HAZ_CODE != .
	gen treat_FHSZ_H = 0
	replace treat_FHSZ_H = treat_period if HAZ_CODE > 1 & HAZ_CODE != .
	gen treat_FHSZ_VH = 0
	replace treat_FHSZ_VH = treat_period if  HAZ_CODE > 2 & HAZ_CODE != .
	
	gen treat_FHSZ_m = 0
	replace treat_FHSZ_m = treat_m if HAZ_CODE != .
	gen treat_FHSZ_H_m = 0
	replace treat_FHSZ_H_m = treat_m if HAZ_CODE > 1 & HAZ_CODE != .
	gen treat_FHSZ_VH_m = 0
	replace treat_FHSZ_VH_m = treat_m if  HAZ_CODE > 2 & HAZ_CODE != .
	// Unlike treat_FHSZ, treat_FHSZ_m needs to be put in as io0.treat_FHSZ_m
	
	* Distance from fire event
	gen dist_miles = NEAR_DIST * 62.1371
	// I think ARCGIS put the distances in fractions of 100km? So, .14 roughly corresponds to 10 miles...
		
	gen close_1 = 0
	replace close_1 = 1 if dist_miles < 1
	gen close_2 = 0
	replace close_2 = 1 if dist_miles < 2
	gen close_5 = 0
	replace close_5 = 1 if dist_miles < 5
	
	gen treat_close_1 = 0
	replace treat_close_1 = treat_period if dist_miles < 1
	gen treat_close_2 = 0
	replace treat_close_2 = treat_period if dist_miles < 2
	gen treat_close_5 = 0
	replace treat_close_5 = treat_period if dist_miles < 5
	
	* Limit fire events
	sort fire_event
	quietly by fire_event:  gen fire_dup = cond(_N==1,0,_n)
	quietly by fire_event:  egen fire_num_trans = max(fire_dup)
	preserve
		keep fire_event fire_num_trans
		collapse fire_num_trans, by(fire_event)
		sum fire_num_trans, d // of 192 fires, around 110 affected over 100 transactions
		hist fire_num_trans
	restore
	
******************************* Restrict Data ********************************
	* Only transactions that happened 24 months before or after event
	keep if event_sale > -24 & event_sale < 24
	
	* Only fire events that affected over 1000 transactions
	keep if fire_num_trans > 1000
	
	* Only confirmed "parcels"; not lat/long guesses
	keep if  PropertyGeocodeQualityCode == "Parcel"
	
	* Only  residential properties
	keep if strpos(PropertyLandUseStndCode, "RR")
	// May consider controlling for this. For now, limit to just RR101
	keep if PropertyLandUseStndCode == "RR101"
	
	* Trim extreme outlier SalePriceAmount
	sum SalesPriceAmount, d
	keep if inrange(SalesPriceAmount, r(p1), r(p99))

**************************** Decide on house char ****************************
	 local house_char_floats "LotSizeSquareFeet SubEdition YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount FireplaceNumber"
	 foreach x in `house_char_floats' {
	 	disp "`x'"
	 	count if `x' != .
	 }
	 // Not many NoOfStories TotalCalculatedBathCount 
	 // Very few FireplaceNumber TotalRooms 
	 
	 local house_char_strings "OccupancyStatusStndCode BuildingQualityStndCode  BathSourceStndCode HeatingTypeorSystemStndCode AirConditioningTypeorSystemStndC FireplaceFlag"
	 foreach x in `house_char_strings' {
	 	disp "`x'"
	 	count if `x' != ""
	 }
	 // Not many AirConditioningTypeorSystemStndC 
	 // Very few FireplaceFlag
	 
	 * Three levels of housing char from most obs to fewest
	 global house_char_1 "LotSizeSquareFeet YearBuilt TotalBedrooms  TotalCalculatedBathCount i.build_quality"
	 global house_char_2 "LotSizeSquareFeet YearBuilt NoOfStories TotalBedrooms TotalCalculatedBathCount i.build_quality i.heating i.aircond"
	 global house_char_3 "LotSizeSquareFeet YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount FireplaceNumber i.build_quality i.bath_code i.heating i.aircond"
	 
******************************* Diff-in-Diffs ********************************
	// Model 1a: DD period x FHSZ
	// Model 1b: Partial Event Study (period x FHSZ)
	// Model 2: DD period x close
	// Model 3: DDD period x FHSZ x close

********************************** Model 1a **********************************
	xtset sale_tm
	* City and month-year FE
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall , fe i(city) 
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_1}, fe i(city)
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_2}, fe i(city)
	
	* County and month-year FE
		xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall , fe i(FIPS) 
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_1}, fe i(FIPS)
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_2}, fe i(FIPS)
	
	* Zip and month-year FE
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall , fe i(PropertyZip) 
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_1}, fe i(PropertyZip)
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_2}, fe i(PropertyZip)
	
	* Event and month-year FE
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall , fe i(NEAR_FID) 
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_1}, fe i(NEAR_FID)
	xtreg SalesPriceAmount treat_FHSZ FHSZ treat_period spring summer fall ${house_char_2}, fe i(NEAR_FID)
	
*********************** Model 1b.1 - VH FHSZ v. not **************************
	xtset sale_tm
	* City and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall , fe i(city) 
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_1}, fe i(city)
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_2}, fe i(city)
	
	* County and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall , fe i(FIPS) 
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_1}, fe i(FIPS)
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_2}, fe i(FIPS)
	
	* Zip and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall , fe i(PropertyZip) 
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_1}, fe i(PropertyZip)
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_2}, fe i(PropertyZip)
	
	* Event and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall , fe i(NEAR_FID) 
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_1}, fe i(NEAR_FID)
	xtreg SalesPriceAmount io0.treat_FHSZ_VH_m FHSZ_VH io0.treat_m spring summer fall ${house_char_2}, fe i(NEAR_FID)	
	
************************** Model 1b.3 - FHSZ v. not **************************
	xtset sale_tm
	* City and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall , fe i(city) 
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_1}, fe i(city)
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_2}, fe i(city)
	
	* County and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall , fe i(FIPS) 
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_1}, fe i(FIPS)
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_2}, fe i(FIPS)
	
	* Zip and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall , fe i(PropertyZip) 
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_1}, fe i(PropertyZip)
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_2}, fe i(PropertyZip)
	
	* Event and month-year FE
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall , fe i(NEAR_FID) 
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_1}, fe i(NEAR_FID)
	xtreg SalesPriceAmount io0.treat_FHSZ_m FHSZ io0.treat_m spring summer fall ${house_char_2}, fe i(NEAR_FID)	
	
	// I'm noticing two very consistent results: (1) FHSZ has a stong negative additional effect on prices during the first few months following a fire; (2) Homes in general (not just FHSZ) sell for more following a fire event
	
	// My preferred model is using fire event FE (NEAR_FID)
	
	