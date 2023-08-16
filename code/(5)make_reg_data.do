* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk

********************************************************************************
ssc install tabout

clear
global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"

************************* Join Asmt and trans RR data *************************
	use "${data_ztrax}\ztrans_clean\asmt_main_char", clear
	
	keep RowID AssessorParcelNumber UnformattedAssessorParcelNumber PropertyFullStreetAddr PropertyAddressLatitude PropertyAddressLongitude FIPS State PropertyCity PropertyZip NoOfBuildings LotSizeAcres LotSizeSquareFeet PropertyAddressUnitDesignator PropertyAddressMatchType PropertyGeocodeQualityCode SubEdition NoOfUnits OccupancyStatusStndCode PropertyCountyLandUseDescription PropertyCountyLandUseCode PropertyLandUseStndCode BuildingQualityStndCode BuildingQualityStndCodeOriginal BuildingQualityStndCodeOriginal YearBuilt NoOfStories TotalRooms TotalBedrooms FullBath HalfBath TotalCalculatedBathCount BathSourceStndCode HeatingTypeorSystemStndCode AirConditioningTypeorSystemStndC FireplaceFlag FireplaceNumber BatchID
	
	rename BatchID BatchID_asmt
	
	// Might want to play around with PropertyGeocodeQualityCode, PropertyGeocodeQualityCode (drop "VeryLow"? I think I already do that for fire data), PropertyAddressMatchType, NoOfUnits (keep only value of 1?), OccupancyStatusStndCode (drop "I"? Maybe not?)

	* Match on AssessorParcelNumber PropertyAddressLatitude
	duplicates tag AssessorParcelNumber PropertyAddressLatitude , g(dup1)
	drop if dup1 > 0 // 153,243 obs dropped
	drop dup1
	
	merge 1:m AssessorParcelNumber PropertyAddressLatitude using "${data}\fires\main_2018_RR_FHSZ"
	rename _m merge1
	rename BatchID BatchID_trans
	
	preserve	
		keep if merge1 == 3 // 1,037,286 obs merged
		save "${data_ztrax}\merge\asmt_trans_RR_1", replace
	restore
	
	preserve
		keep if merge1 == 2 // 154,285 NOT merged from using
		keep TransId AssessorParcelNumber PropertyAddressLatitude PropertyAddressGeoCodeMatchCode BatchID_trans RecordingDate SalesPriceAmount SalesPriceAmountStndCode PropertyUseStndCode AssessmentLandUseStndCode ymd sale_date ymd_sale year_sale Join_Count SRA INCORP HAZ_CODE HAZ_CLASS FHSZ_dup merge1
		rename PropertyAddressLatitude PropertyAddressLatitude_Trans
		save "${data_ztrax}\merge\asmt_trans_RR_1_nomerge", replace
	restore
	
	keep if merge1 == 1
	drop TransId PropertyAddressGeoCodeMatchCode BatchID_trans RecordingDate SalesPriceAmount SalesPriceAmountStndCode PropertyUseStndCode AssessmentLandUseStndCode ymd sale_date ymd_sale year_sale Join_Count SRA INCORP HAZ_CODE HAZ_CLASS FHSZ_dup merge1

	* Match on AssessorParcelNumber
	duplicates tag AssessorParcelNumber, g(dup2)
	drop if dup2 > 0 // 153,243 obs dropped
	drop dup2
	
	merge 1:m AssessorParcelNumber using "${data_ztrax}\merge\asmt_trans_RR_1_nomerge"
	rename _m merge2
	
	keep if merge2 == 3 //  40,931 obs merged; still 113,354 unmerged from using
	save "${data_ztrax}\merge\asmt_trans_RR_2", replace
	append using "${data_ztrax}\merge\asmt_trans_RR_1"
	
	* Make quarterly sale date for HPI merge below
	gen sale_date_d = date(sale_date, "YMD")
	format sale_date_d %td
	gen sale_date_q = qofd(sale_date_d)
	format sale_date_q %tq
	
	save "${data_ztrax}\ztrans_clean\asmt_trans_RR"
	// This is "wide" data in the sense that each obs is a transaction
	
************************* Adjust SalesPriceAmount by HPI **********************
	// use "${data_ztrax}\ztrans_clean\asmt_trans_RR", clear
	
	* Pull in HPI data
	import delimited "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\HPI\CASTHPI.csv", clear

	* Make dates into quarters
	gen date_d = date(date, "YMD")
	format date_d %td
	gen sale_date_q = qofd(date_d)
	format sale_date_q %tq
	
	* Merge on sale_date_q
	merge 1:m sale_date_q using "${data_ztrax}\ztrans_clean\asmt_trans_RR"
	keep if _merge == 3
	drop _m date_d
	
	* Normalize to 2016q1 dollars with HPI (545.42)
	gen HPI_factor = 545.42 / casthpi
	gen SalesPriceAmount_HPI = SalesPriceAmount * HPI_factor
	
	save "${data_ztrax}\ztrans_clean\asmt_trans_RR_HPI"
	
	// Quarterly Case-Schiller HPI for CA (not already seasonally adjusted) from FRED https://fred.stlouisfed.org/series/CASTHPI
************************* Join Asmtt-trans and fire data *********************
	// use "${data_ztrax}\ztrans_clean\asmt_trans_RR_HPI"
	drop sale_date
	
	merge 1:m TransId using "${data}\fires\fire_near_event_time"
	keep if _m == 3 // 625,675 obs
	drop _m
	
	save "${data_ztrax}\reg_data_RR"
	
	// Note that this data is now "long" in the sense that each observation is a transaction by fire event. A transaction will show up as many times as the number of fire events to which it is relevant. It will be treated as both a treated for an event that happened before it and control for an event that happened after. 
	// Maybe I should add in a dummy variable that indicates whether the control transaction occurred within 3 months after a fire event? For all treated, this would be 0. For true controls, this would be 0. But for a control transaction which occurred.
	
	
	