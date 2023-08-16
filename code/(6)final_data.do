* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk
* NOTE: This dofile makes three primary datasets which I use in regression analysis. The first is "${data_ztrax}\reg_data_RR_event_study" -- a transaction-event level dataset for house price regressions; The second is "${data_ztrax}\reg_data_RR_collapsed" -- a fire-event-area level dataset for plotting quantity of houses sold in each event-time month by FHSZ, close, and not.

********************************************************************************
//ssc install tabout

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"

use "${data_ztrax}\reg_data_RR", clear

******************************* Edit Variables *******************************
	* Make PropertyCity into indicator
	egen city = group(PropertyCity)
	egen my = group(sale_tm)
	egen event = group(event_sale) if event_sale > -24 & event_sale < 24
	// this makes event time 0 (during fire) into event == 24
	egen fire_event = group(NEAR_FID)
	
	* Fill out FHSZ
	replace HAZ_CODE = 0 if HAZ_CODE == .
	
	* Make house char factor vars
	egen occupy = group(OccupancyStatusStndCode)
	egen build_quality = group(BuildingQualityStndCode)
	egen bath_code = group(BathSourceStndCode) 
	egen heating = group(HeatingTypeorSystemStndCode)
	egen aircond = group(AirConditioningTypeorSystemStndC)
	
	* Southern CA indicator
	gen south = 0
	replace south = 1 if PropertyAddressLongitude < 35
	
	* seasonal controls
	gen month = month(sale_date)
	gen spring = 0
	replace spring = 1 if month == 3 | month == 4 | month == 5
	gen summer = 0
	replace summer = 1 if month == 6 | month == 7 | month == 8
	gen fall = 0
	replace fall = 1 if month == 9 | month == 10 | month == 11
	
	* Label LRA areas
	gen LRA = 0
	replace LRA = 1 if SRA == ""
	
	gen treat_LRA = 0
	replace treat_LRA =event if SRA == ""
	
	* FHSZ	
	gen not_FHSZ = 0
	replace not_FHSZ = 1 if HAZ_CODE == 0
	gen FHSZ = 0
	replace FHSZ = 1 if HAZ_CODE != 0
	gen FHSZ_H = 0
	replace FHSZ_H = 1 if HAZ_CODE > 1
	gen FHSZ_VH = 0
	replace FHSZ_VH = 1 if  HAZ_CODE > 2 
	gen not_FHSZ_VH = 0
	replace not_FHSZ_VH = 1 if HAZ_CODE != 3
	
	gen treat_FHSZ = 0
	replace treat_FHSZ = event if HAZ_CODE != 0
	gen treat_FHSZ_H = 0
	replace treat_FHSZ_H = event if HAZ_CODE > 1 
	gen treat_FHSZ_VH = 0
	replace treat_FHSZ_VH = event if  HAZ_CODE > 2
	gen treat_not_FHSZ = 0
	replace treat_not_FHSZ = event if HAZ_CODE == 0
	gen treat_not_FHSZ_VH = 0
	replace treat_not_FHSZ_VH = event if HAZ_CODE != 3
	
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
	replace treat_close_1 = event if dist_miles < 1
	gen treat_close_2 = 0
	replace treat_close_2 = event if dist_miles < 2
	gen treat_close_5 = 0
	replace treat_close_5 = event if dist_miles < 5
	gen treat_not_close = 0
	replace treat_not_close = event if dist_mile > 5
	
	* Double diff -- close by FHSZ
	gen treat_close_1_FHSZ_VH = 0
	replace treat_close_1_FHSZ_VH = treat_close_1 if HAZ_CODE > 2
	gen treat_close_2_FHSZ_VH = 0
	replace treat_close_2_FHSZ_VH = treat_close_2 if HAZ_CODE > 2
	gen treat_close_5_FHSZ_VH = 0
	replace treat_close_5_FHSZ_VH = treat_close_5 if HAZ_CODE > 2
	gen treat_close_1_FHSZ = 0
	replace treat_close_1_FHSZ = treat_close_1 if HAZ_CODE != 0
	gen treat_close_2_FHSZ = 0
	replace treat_close_2_FHSZ = treat_close_2 if HAZ_CODE != 0
	gen treat_close_5_FHSZ = 0
	replace treat_close_5_FHSZ = treat_close_5 if HAZ_CODE != 0
	
	* EVENT TIME (less lazy)
	gen event_0 = 0
	replace event_0 = 1 if event_sale == 0
	label var event_0 "0"
	gen notFHSZ_event_0 = 0
	replace notFHSZ_event_0 = 1 if event_sale == 0 & FHSZ == 0
	label var notFHSZ_event_0 "0"
	gen FHSZ_VH_event_0 = 0
	replace FHSZ_VH_event_0 = 1 if event_sale == 0 & FHSZ_VH == 1
	label var FHSZ_VH_event_0 "0"
	gen notClose_event_0 = 0
	replace notClose_event_0 = 1 if event_sale == 0 &  dist_miles > 5
	label var notClose_event_0 "0"
	gen close_2_event_0 = 0
	replace close_2_event_0 = 1 if event_sale == 0 & dist_miles < 2
	label var close_2_event_0 "0"
	gen close_1_event_0 = 0
	replace close_1_event_0 = 1 if event_sale == 0 & dist_miles < 1
	label var close_1_event_0 "0"
	gen FHSZ_VH_close_2_event_0 = 0
	
	* Triple Diff
	replace FHSZ_VH_close_2_event_0 = 1 if event_sale == 0 & dist_miles < 2 & FHSZ_VH == 1
	label var FHSZ_VH_close_2_event_0 "0"
	
	forval x = 1/24 {
		gen event_lead`x' = 0
		replace event_lead`x' = 1 if event_sale == -`x'
		label var event_lead`x' "-`x'"
		gen event_lag`x' = 0
		replace event_lag`x' = 1 if event_sale == `x'
		label var event_lag`x' "`x'"
		
		gen notFHSZ_event_lead`x' = 0
		replace notFHSZ_event_lead`x' = 1 if event_sale == -`x' & FHSZ == 0
		label var notFHSZ_event_lead`x' "-`x'"
		gen notFHSZ_event_lag`x' = 0
		replace notFHSZ_event_lag`x' = 1 if event_sale == `x' & FHSZ == 0
		label var notFHSZ_event_lag`x' "`x'"
		
		gen FHSZ_VH_event_lead`x' = 0
		replace FHSZ_VH_event_lead`x' = 1 if event_sale == -`x' & FHSZ_VH == 1
		label var FHSZ_VH_event_lead`x' "-`x'"
		gen FHSZ_VH_event_lag`x' = 0
		replace FHSZ_VH_event_lag`x' = 1 if event_sale == `x' & FHSZ_VH == 1
		label var FHSZ_VH_event_lag`x' "`x'"
		
		gen notClose_event_lead`x' = 0
		replace notClose_event_lead`x' = 1 if event_sale == -`x' & dist_miles > 5
		label var notClose_event_lead`x' "-`x'"
		gen notClose_event_lag`x' = 0
		replace notClose_event_lag`x' = 1 if event_sale == `x' & dist_miles > 5
		label var notClose_event_lag`x' "`x'"
		
		gen close_2_event_lead`x' = 0
		replace close_2_event_lead`x' = 1 if event_sale == -`x' & dist_miles < 2
		label var close_2_event_lead`x' "-`x'"
		gen close_2_event_lag`x' = 0
		replace close_2_event_lag`x' = 1 if event_sale == `x' & dist_miles < 2
		label var close_2_event_lag`x' "`x'"
		
		gen close_1_event_lead`x' = 0
		replace close_1_event_lead`x' = 1 if event_sale == -`x' & dist_miles < 1
		label var close_1_event_lead`x' "-`x'"
		gen close_1_event_lag`x' = 0
		replace close_1_event_lag`x' = 1 if event_sale == `x' & dist_miles < 1
		label var close_1_event_lag`x' "`x'"
		
		* Triple Diff
		gen FHSZ_VH_close_2_event_lead`x' = 0
		replace FHSZ_VH_close_2_event_lead`x' = 1 if event_sale == -`x' & dist_miles < 2 & FHSZ_VH == 1
		label var FHSZ_VH_close_2_event_lead`x' "-`x'"
		gen FHSZ_VH_close_2_event_lag`x' = 0
		replace FHSZ_VH_close_2_event_lag`x' = 1 if event_sale == `x' & dist_miles < 2 & FHSZ_VH == 1
		label var FHSZ_VH_close_2_event_lag`x' "`x'"
	}
	
	* Limit fire events
	sort fire_event
	quietly by fire_event:  gen fire_dup = cond(_N==1,0,_n)
	quietly by fire_event:  egen fire_num_trans = max(fire_dup)
	preserve
		keep fire_event fire_num_trans
		collapse fire_num_trans, by(fire_event)
		sum fire_num_trans, d // of 192 fires, around 110 affected over 100 transactions
		// hist fire_num_trans
	restore
	
	* Make indicator for TransId that have all positive event_sale times
	gen post_events =  0
	replace post_events =  1 if event_sale >=0
	
	* Make post x LRA interaction
	gen post_LRA = 0
	replace post_LRA = 1 if LRA == 1 & post_events == 1
	
	* Make post x close interaction
	gen post_close_1 = 0
	replace post_close_1 = 1 if close_1 == 1 & post_events == 1
	gen post_close_2 = 0
	replace post_close_2 = 1 if close_2 == 1 & post_events == 1
	gen post_close_5 = 0
	replace post_close_5 = 1 if close_5 == 1 & post_events == 1
	
	* Make post x FHSZ interaction
	gen post_FHSZ_VH = 0
	replace post_FHSZ_VH = 1 if FHSZ_VH == 1 & post_events == 1
	gen post_FHSZ_H = 0
	replace post_FHSZ_H = 1 if FHSZ_H == 1 & post_events == 1
	gen post_FHSZ = 0
	replace post_FHSZ = 1 if FHSZ == 1 & post_events == 1
	gen post_not_FHSZ = 0
	replace post_not_FHSZ = 1 if not_FHSZ == 1 & post_events == 1
	gen post_not_FHSZ_VH = 0
	replace post_not_FHSZ_VH = 1 if not_FHSZ_VH == 1 & post_events == 1
	
	* Make post x FHSZ + LRA interaction
	gen post_not_FHSZ_LRA = 0
	replace post_not_FHSZ_LRA = post_LRA if not_FHSZ == 1 
	gen post_not_FHSZ_VH_LRA = 0
	replace post_not_FHSZ_VH_LRA = post_LRA if not_FHSZ_VH == 1 
	
	* Make FHSZ + LRA interaction
	gen not_FHSZ_LRA = 0
	replace not_FHSZ_LRA = LRA if not_FHSZ == 1
	gen not_FHSZ_VH_LRA = 0
	replace not_FHSZ_VH_LRA = LRA if not_FHSZ_VH == 1

	
	* How many transactions experienced more than one fire event within 3 months before purchase? Within 12 months before purchase?
	gen event_3m0 = 0
	replace event_3m0 = 1 if event_sale == 1 | event_sale == 2 | event_sale == 3
	gen event_3m = 0
	replace event_3m = 1 if event_sale == 0 | event_sale == 1 | event_sale == 2 | event_sale == 3
	quietly bysort TransId:  egen event_3m_sum = sum(event_3m)
	
	gen event_12m = 0
	replace event_12m = 1 if event_sale == 0 | event_sale == 1 | event_sale == 2 | event_sale == 3 | event_sale == 4 | event_sale == 5 | event_sale == 6 | event_sale == 7 | event_sale == 8 | event_sale == 9 | event_sale == 10 | event_sale == 11 | event_sale == 12
	quietly bysort TransId:  egen event_12m_sum = sum(event_12m)
	
	sum event_3m_sum, d // Max two events in 3 months
	sum event_12m_sum, d // Max 4 events in 12 months
	
	* Make 3 month treatment interactions
	gen event_3m0_FHSZ_VH = 0
	replace event_3m0_FHSZ_VH = event_3m0 if FHSZ_VH == 1
	gen event_3m_FHSZ_VH = 0
	replace event_3m_FHSZ_VH = event_3m if FHSZ_VH == 1
	gen event_3m0_FHSZ = 0
	replace event_3m0_FHSZ = event_3m0 if FHSZ == 1
	gen event_3m_FHSZ = 0
	replace event_3m_FHSZ = event_3m if FHSZ == 1
	
	gen event_3m0_close_1 = 0
	replace event_3m0_close_1 = event_3m0 if close_1 == 1
	gen event_3m_close_1 = 0
	replace event_3m_close_1 = event_3m if close_1 == 1
	gen event_3m0_close_2 = 0
	replace event_3m0_close_2 = event_3m0 if close_2 == 1
	gen event_3m_close_2 = 0
	replace event_3m_close_2 = event_3m if close_2 == 1
	
	gen event_3m0_FHSZ_VH_close_2 = 0
	replace event_3m0_FHSZ_VH_close_2 = event_3m0_FHSZ_VH if close_2 == 1
	gen event_3m_FHSZ_VH_close_2 = 0
	replace event_3m_FHSZ_VH_close_2 = event_3m_FHSZ_VH if close_2 == 1	
	
	* log SalesPriceAmount_HPI
	gen log_SalesPriceAmount_HPI = ln(SalesPriceAmount_HPI)	
	
	* rename fire event indicator (NEAR_FID)
	rename NEAR_FID FID
	
******************************* Restrict obs ********************************
	* Only transactions that happened 12 months before or after event
	keep if event_sale > -25 & event_sale < 25
	
	* Only fire events that affected over 1000 transactions
	//keep if fire_num_trans > 1000
	
	* Only confirmed "parcels"; not lat/long guesses
	keep if  PropertyGeocodeQualityCode == "Parcel"
	
	* Only  residential properties
	keep if strpos(PropertyLandUseStndCode, "RR")
	// May consider controlling for this. For now, limit to just RR101
	keep if PropertyLandUseStndCode == "RR101"

	* Trim extreme outlier SalesPriceAmount_HPI
	sum SalesPriceAmount_HPI, d
	keep if inrange(SalesPriceAmount_HPI, r(p1), r(p99))
	
	*(Special) Drop transaction-events which are being used as controls (pre-event witin 12 months) for event(s) that happen after they were treated. (I.e. If a transaction has any positive event_time observations (up to event_time = 12?), drop its negative event_time obs.
	sort TransId event_sale
	quietly by TransId:  gen TransId_dup = cond(_N==1,0,_n)
	quietly by TransId:  egen TransId_dup_max = max(TransId_dup)
	quietly by TransId:  egen event_sale_max = max(event_sale) if event_sale <13
	quietly by TransId:  egen event_sale_min = min(event_sale) 
	
	* Version 1
	*NOTE: Comment this out before running the "Make Quanitty Sold Data" section below
//  	drop if TransId_dup_max > 0 & event_sale < 0 & event_sale_max > -1 & event_sale_max < . & event_sale_min < 0 // 23,721 obs dropped
	
	* Version 2
// 	drop if TransId_dup_max > 0 & event_sale < 0 & event_sale_max > -1 & event_sale_max < . & event_sale_min < 0 & (HAZ_CODE != 0 | close_2 == 1)
**************************** Bayesian variables ***************************	
	
	// Since I don't think all event times will be populated with transactions that have experiences 3 or maybe even 2 events, I may have to do these as DD? 
	// OR I could include event_3m_sum and event_12m_sum as a continuous interaction to see how experiencing an additional fire event before purchase.
	// Not really conducive to event study
	
	* Make incremental exposure variables (one fire in 3 months; two fires in three months)
	gen event_3m_sum_1 = 0
	replace event_3m_sum_1 = 1 if event_3m_sum == 1
	gen event_3m_sum_2 = 0
	replace event_3m_sum_2 = 1 if event_3m_sum == 2
	
	* Exposure interaction variables	
	gen event_3m_sum_FHSZ = 0
	replace event_3m_sum_FHSZ = event_3m_sum if FHSZ == 1
	gen event_3m_sum_FHSZ_VH = 0
	replace event_3m_sum_FHSZ_VH = event_3m_sum if FHSZ_VH == 1
	gen event_3m_sum_close_1 = 0
	replace event_3m_sum_close_1 = event_3m_sum if close_1 == 1
	gen event_3m_sum_close_2 = 0
	replace event_3m_sum_close_2 = event_3m_sum if close_2 == 1
	
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
	 global house_char_2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond"
	 global house_char_3 "LotSizeSquareFeet YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount i.build_quality i.heating i.aircond FireplaceNumber i.bath_code"
	 
**************************** Label DDD variables ****************************
	label var log_SalesPriceAmount_HPI "Sale Price"
	label var post_not_FHSZ_LRA "post x LRA x non-FHSZ"
	label var post_not_FHSZ_VH_LRA "post x LRA x not very-high FHSZ"
	label var post_FHSZ_VH "post x very high FHSZ"
	label var post_FHSZ_H "post x high FHSZ"
	label var post_FHSZ "post x FHSZ"
	label var post_not_FHSZ "post x non-FHSZ"
	label var post_not_FHSZ_VH "post x not very-high FHSZ"
	label var post_LRA "post x LRA"
	label var post_close_2 "post x close"
	label var not_FHSZ_LRA "LRA x non-FHSZ"
	label var not_FHSZ_VH_LRA "LRA x not very-high FHSZ"
	label var FHSZ_VH "very-high FHSZ" 
	label var FHSZ_H "high FHSZ" 
	label var FHSZ "FHSZ" 
	label var not_FHSZ "non-FHSZ"
	label var not_FHSZ_VH "no t very-high FHSZ"
	label var LRA "LRA"
	label var close_2 "close"
	label var post_events "post"
	 
********************************* Save data **********************************
	save "${data_ztrax}\reg_data_RR_event_study_v0", replace

// 	"${data_ztrax}\reg_data_RR_event_study_v2" is created by commenting out "version 1" but not "version 2"
// 	"${data_ztrax}\reg_data_RR_event_study_v1" is created by commenting out "version 2" but not "version 1" -- use this for DD price regs
// 	"${data_ztrax}\reg_data_RR_event_study_v0" is created by commenting out both "version 1" and "version 2"
	
****************************************************************************
************************** Make quantity sold data ***************************
****************************************************************************
use "${data_ztrax}\reg_data_RR_event_study_v2", clear
	
	keep if fire_num_trans > 1000
	
	gen num_fire_months = cont_tm - alarm_tm 
	
	* Unoccupied
	gen unoccupied = 0 if occupy == 1
	replace unoccupied = 1 if occupy == 2
	
	// I do not count as 0 transactions FIDs that have no obs in a given event_sale; I instead leave them as missing. For instance, only 9 FID have any transactions at event_sale == 0, whereas normally there are around 45. This may look weird on the surface (especially for event time 0), but is fine for the other event times since most are missing due to calendar date cutoffs of my data. I might still impute 0 for event_sale == 0 though...
	
	// I just remembered that I deleted negative event time sales if they were also in a  positive event time

*************************** Collapse by FIPS ***************************
	* Collapse by FID and event time 
	preserve 
		bysort FID event_sale: egen FIPS_mode = mode(FIPS)
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_all = TransId (mean) unoccupied, by(FID event_sale)
		* Make obs for every FID-event_sale interactions
		
		* Collapse (sum) num_trans_all
		
		gen log_num_trans_all = ln(num_trans_all)
		gen trans_per_month_all = num_trans_all
		replace trans_per_month_all = num_trans_all / num_fire_months if event_sale == 0
		gen log_trans_per_month_all = ln(trans_per_month_all)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_all", replace
	restore

	* Collapse by FID and FHSZ and event time
	preserve 
		bysort FID HAZ_CODE event_sale: egen FIPS_mode = mode(FIPS)
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_FHSZ = TransId (mean) unoccupied, by(FID HAZ_CODE event_sale)
		gen log_num_trans_FHSZ = ln(num_trans_FHSZ)	
		gen trans_per_month_FHSZ = num_trans_FHSZ
		replace trans_per_month_FHSZ = num_trans_FHSZ / num_fire_months if event_sale == 0
		gen log_trans_per_month_FHSZ = ln(trans_per_month_FHSZ)		
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZ", replace
	restore

	* Collapse by FID and close <2 and >2 and event time
	preserve 
		bysort FID close_2 event_sale: egen FIPS_mode = mode(FIPS)	
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_close2 = TransId (mean) unoccupied, by(FID close_2 event_sale)
		gen log_num_trans_close2 = ln(num_trans_close2)
		gen trans_per_month_close2 = num_trans_close2
		replace trans_per_month_close2 = num_trans_close2 / num_fire_months if event_sale == 0
		gen log_trans_per_month_close2 = ln(trans_per_month_close2)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_close2", replace
	restore

	* Collapse by FID close <5 and >5 and event time
	preserve 
		bysort FID close_5 event_sale: egen FIPS_mode = mode(FIPS)	
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_close5 = TransId (mean) unoccupied, by(FID close_5 event_sale)
		gen log_num_trans_close5 = ln(num_trans_close5)
		gen trans_per_month_close5 = num_trans_close5
		replace trans_per_month_close5 = num_trans_close5 / num_fire_months if event_sale == 0
		gen log_trans_per_month_close5 = ln(trans_per_month_close5)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_close5", replace
	restore
	
	* Collapse by FID close2 and FHSZ and event time
	preserve 
		bysort FID HAZ_CODE close_2 event_sale: egen FIPS_mode = mode(FIPS)	
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_FHSZclose2 = TransId (mean) unoccupied, by(FID close_2 HAZ_CODE event_sale)
		gen log_num_trans_FHSZclose2 = ln(num_trans_FHSZclose2)		
		gen trans_per_month_FHSZclose2 = num_trans_FHSZclose2
		replace trans_per_month_FHSZclose2 = num_trans_FHSZclose2 / num_fire_months if event_sale == 0
		gen log_trans_per_month_FHSZclose2 = ln(trans_per_month_FHSZclose2)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZclose2", replace
	restore
	
	* Collapse by FID close5 and FHSZ and event time
	preserve 
		bysort FID HAZ_CODE close_5 event_sale: egen FIPS_mode = mode(FIPS)	
		collapse (first) FIPS_mode sale_tm num_fire_months (count) num_trans_FHSZclose5 = TransId (mean) unoccupied, by(FID close_5 HAZ_CODE event_sale)
		gen log_num_trans_FHSZclose5 = ln(num_trans_FHSZclose5)		
		gen trans_per_month_FHSZclose5 = num_trans_FHSZclose5
		replace trans_per_month_FHSZclose5 = num_trans_FHSZclose5 / num_fire_months if event_sale == 0
		gen log_trans_per_month_FHSZclose5 = ln(trans_per_month_FHSZclose5)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZclose5", replace
	restore
	
	* Append them all together
	use "${data_ztrax}\collapsed\reg_data_RR_collapsed_all", clear
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZ"
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_close2"
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_close5"
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZclose2"
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_FHSZclose5"
	
	* Gen event time indicators
	gen event_0 = 0
	replace event_0 = 1 if event_sale == 0
	label var event_0 "0"
	forval x = 1/24 {
		gen event_lead`x' = 0
		replace event_lead`x' = 1 if event_sale == -`x'
		label var event_lead`x' "-`x'"
		gen event_lag`x' = 0
		replace event_lag`x' = 1 if event_sale == `x'
		label var event_lag`x' "`x'"
	}
	
	* Make DD vars
	gen FHSZ_VH = 0
	replace FHSZ_VH = 1 if HAZ_CODE == 3
	gen post = 0 
	replace post = 1 if event_sale > -1
	gen post_FHSZ_VH = 0
	replace post_FHSZ_VH = post if FHSZ_VH == 1
	gen post_close_2 = 0
	replace post_close_2 = post if close_2 == 1
	gen post_FHSZ_VH_close_2 = 0
	replace post_FHSZ_VH_close_2 = post_FHSZ_VH if close_2 == 1
	
	save "${data_ztrax}\reg_data_RR_collapsed_v2", replace
	
// "${data_ztrax}\reg_data_RR_collapsed" is created by commenting out both "version 1" and "version 2" above (using "${data_ztrax}\reg_data_RR_event_study_v0")
// 	"${data_ztrax}\reg_data_RR_collapsed_v2" is created by commenting out "version 1" but not "version 2" (using "${data_ztrax}\reg_data_RR_event_study_v2")

************************* Collapse by zip & city ************************
use "${data_ztrax}\reg_data_RR_event_study_v2", clear
	
	keep if fire_num_trans > 1000
	
	gen num_fire_months = cont_tm - alarm_tm 
	
	* Unoccupied
	gen unoccupied = 0 if occupy == 1
	replace unoccupied = 1 if occupy == 2
	
	// I do not count as 0 transactions FIDs that have no obs in a given event_sale; I instead leave them as missing. For instance, only 9 FID have any transactions at event_sale == 0, whereas normally there are around 45. This may look weird on the surface (especially for event time 0), but is fine for the other event times since most are missing due to calendar date cutoffs of my data. I might still impute 0 for event_sale == 0 though...
	
	// I just remembered that I deleted negative event time sales if they were also in a  positive event time
	
foreach FE in PropertyCity PropertyZip FIPS  {
	* Collapse by FE and event time 
	preserve 
		bysort FID event_sale: egen `FE'_mode = mode(`FE')
		collapse (first) `FE'_mode sale_tm num_fire_months (count) num_trans_all = TransId (mean) unoccupied, by(`FE' event_sale)
		* Make obs for every FID-event_sale interactions
		
		* Collapse (sum) num_trans_all
		
		gen log_num_trans_all = ln(num_trans_all)
		gen trans_per_month_all = num_trans_all
		replace trans_per_month_all = num_trans_all / num_fire_months if event_sale == 0
		gen log_trans_per_month_all = ln(trans_per_month_all)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_all", replace
	restore

	* Collapse by FID and FHSZ and event time
	preserve 
		bysort FID HAZ_CODE event_sale: egen `FE'_mode = mode(`FE')
		collapse (first) `FE'_mode sale_tm num_fire_months (count) num_trans_FHSZ = TransId (mean) unoccupied, by(`FE' HAZ_CODE event_sale)
		gen log_num_trans_FHSZ = ln(num_trans_FHSZ)	
		gen trans_per_month_FHSZ = num_trans_FHSZ
		replace trans_per_month_FHSZ = num_trans_FHSZ / num_fire_months if event_sale == 0
		gen log_trans_per_month_FHSZ = ln(trans_per_month_FHSZ)		
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_FHSZ", replace
	restore
	preserve
	* Append them all together
	use "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_all", clear
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_FHSZ"
	
	* Gen event time indicators
	gen event_0 = 0
	replace event_0 = 1 if event_sale == 0
	label var event_0 "0"
	forval x = 1/24 {
		gen event_lead`x' = 0
		replace event_lead`x' = 1 if event_sale == -`x'
		label var event_lead`x' "-`x'"
		gen event_lag`x' = 0
		replace event_lag`x' = 1 if event_sale == `x'
		label var event_lag`x' "`x'"
	}
	
	* Make DD vars
	gen FHSZ_VH = 0
	replace FHSZ_VH = 1 if HAZ_CODE == 3
	gen not_FHSZ = 0
	replace not_FHSZ = 1 if HAZ_CODE == 0
	gen not_FHSZ_VH = 0
	replace not_FHSZ_VH = 1 if HAZ_CODE !=3
	
	gen post = 0 
	replace post = 1 if event_sale > -1
	gen post_FHSZ_VH = 0
	replace post_FHSZ_VH = post if FHSZ_VH == 1
	gen post_not_FHSZ = 0
	replace post_not_FHSZ = post if not_FHSZ == 1
	gen post_not_FHSZ_VH = 0
	replace post_not_FHSZ_VH = post if not_FHSZ_VH == 1
	
	if "`FE'" == "PropertyZip" {
		rename PropertyZip_mode zip_mode
		local FE2 = "zip"
	}
	if "`FE'" == "PropertyCity" {
		rename PropertyCity_mode city_mode
		local FE2 = "city"
	}
	else {
		local FE2 = "FIPS"
	}
	
	save "${data_ztrax}\reg_data_RR_collapsed_`FE2'_v2", replace
	restore
}

********************** Collapse by FIPS (not using mode) *********************
// So, can't construct number of tansactions per month during fire (event = 0)
use "${data_ztrax}\reg_data_RR_event_study_v2", clear
	
	keep if fire_num_trans > 1000
	
	gen num_fire_months = cont_tm - alarm_tm 
	
	* Unoccupied
	gen unoccupied = 0 if occupy == 1
	replace unoccupied = 1 if occupy == 2
	
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

	
foreach FE in FIPS   {
	* Collapse by FE and event time
	preserve 
		collapse (count) num_trans_all = TransId (mean) unoccupied, by(`FE' event_sale)
		* Make obs for every FID-event_sale interactions
		
		* Collapse (sum) num_trans_all
		
		gen log_num_trans_all = ln(num_trans_all)
		gen trans_per_month_all = num_trans_all
		replace trans_per_month_all = . if event_sale == 0
		gen log_trans_per_month_all = ln(trans_per_month_all)
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_noMode", replace
	restore

	* Collapse by FID and FHSZ and event time
	preserve 
		collapse (count) num_trans_FHSZ = TransId (mean) unoccupied, by(`FE' HAZ_CODE event_sale)
		gen log_num_trans_FHSZ = ln(num_trans_FHSZ)	
		gen trans_per_month_FHSZ = num_trans_FHSZ
		replace trans_per_month_FHSZ = . if event_sale == 0
		gen log_trans_per_month_FHSZ = ln(trans_per_month_FHSZ)		
		save "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_byFHSZ_noMode", replace
	restore
	preserve
	* Append them all together
	use "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_noMode", clear
	append using "${data_ztrax}\collapsed\reg_data_RR_collapsed_`FE'_byFHSZ_noMode"
	
	* Gen event time indicators
	gen event_0 = 0
	replace event_0 = 1 if event_sale == 0
	label var event_0 "0"
	forval x = 1/24 {
		gen event_lead`x' = 0
		replace event_lead`x' = 1 if event_sale == -`x'
		label var event_lead`x' "-`x'"
		gen event_lag`x' = 0
		replace event_lag`x' = 1 if event_sale == `x'
		label var event_lag`x' "`x'"
	}
	
	* Make DD vars
	gen FHSZ_VH = 0
	replace FHSZ_VH = 1 if HAZ_CODE == 3
	gen not_FHSZ = 0
	replace not_FHSZ = 1 if HAZ_CODE == 0
	gen not_FHSZ_VH = 0
	replace not_FHSZ_VH = 1 if HAZ_CODE !=3
	
	gen post = 0 
	replace post = 1 if event_sale > -1
	gen post_FHSZ_VH = 0
	replace post_FHSZ_VH = post if FHSZ_VH == 1
	gen post_not_FHSZ = 0
	replace post_not_FHSZ = post if not_FHSZ == 1
	gen post_not_FHSZ_VH = 0
	replace post_not_FHSZ_VH = post if not_FHSZ_VH == 1
	
	if "`FE'" == "PropertyZip" {
		local FE2 = "zip"
	}
	if "`FE'" == "PropertyCity" {
		local FE2 = "city"
	}
	else {
		local FE2 = "FIPS"
	}
	
	save "${data_ztrax}\reg_data_RR_collapsed_`FE2'_noMode", replace
	restore
}
		