* Author: 	Trevor Woolley
* Date:		Jan 20, 2022
* Project:	Fire Risk
* RUN AFTER ARCGIS CODE
* Purpose:	This makes two datasets--"${data}\fires\main_2018_RR_FHSZ" and "${data}\fires\fire_near_event_time"--both of which come from data created in ARCGIS and will be merged with the main data in (5)make_reg_data. 

********************************************************************************
ssc install tabout

clear
global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
******************* Make Stata data from transaction GIS data ***************
	// This is bc IN_FID in the "near" GIS data corresponds to (I think) OBJECTID in main_2018_RR_XYTableToPoint_30
	 
	import excel "${gis_data}\main_2018_RR_XYTableToPoint_30_TableToExcel.xlsx", firstrow clear

	* Just save the IN_FID TransId as xwalk
	rename OBJECTID IN_FID
	keep IN_FID TransId AssessorParcelNumber sale_date
	save "${data}\fires\INFID_TransId_xwalk"

*************************** Select fire event subset *************************
	import excel "${gis_data}\fire_merge\firep20_1_2015_18_TableToExcel.xlsx", sheet("firep20_1_2015_18_TableToExcel") firstrow clear

	* Select "large wildfires" (larger than 1,000 acres as defined by EPA)
	sum GIS_ACRES, d // something like 85% of the fire events between 2016 and 2018

	count if GIS_ACRES > 1000 // 211 fire events (200 end up being relevant to RR homes after later merge)

	* Make dataset of just these fire events (Assume that other fires don't matter)
	keep if GIS_ACRES > 1000

	keep FID YEAR_ CAUSE GIS_ACRES ALARM_DATE CONT_DATE
	rename FID NEAR_FID
	save "${data}\fires\large_fires", replace

*************************** Merge with nearness data *************************
	import excel "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires\fire_merge\main_2018_RR_neartable_TableToExcel.xlsx", sheet("main_2018_RR_neartable_TableToE") firstrow

	merge m:1 NEAR_FID using "${data}\fires\large_fires"
	keep if _merge == 3 // 653,975 fire by transaction obs
	drop _merge

	save "${data}\fires\fire_event_near" // fire event by transaction data 
	// includes large fire data (cause, size, date), transaction ID, and distance of home from fire event

************************ Merge with transaction data *************************
	* RR transactions
	merge m:1 IN_FID using "${data}\fires\INFID_TransId_xwalk"

******************************* Make Event Time ******************************
	* Reformat fire dates into monthly Stata time (start and finish)
	rename sale_date SALE_DATE
	gen alarm_date = dofc(ALARM_DATE)
	gen cont_date = dofc(CONT_DATE)
	gen sale_date = dofc(SALE_DATE)
	format alarm_date %td
	format cont_date %td
	format sale_date %td
	
	gen alarm_tm = mofd(alarm_date)
	format alarm_tm %tm
	gen cont_tm = mofd(cont_date) 
	format cont_tm %tm
	gen sale_tm = mofd(sale_date)
	format sale_tm %tm

	* Make event time (transaction date - fire date; with 0 being during fire)
	gen sale_alarm = sale_tm - alarm_tm
	gen sale_cont = sale_tm - cont_tm

	gen event_sale = sale_alarm if sale_alarm < 0 
	replace event_sale = sale_cont if sale_cont > 0
	replace event_sale = 0 if sale_alarm > 0 & sale_cont < 0
		
	keep if _m == 3
	* Keep minimal vars
	keep TransId NEAR_FID NEAR_DIST NEAR_RANK YEAR_ CAUSE GIS_ACRES SALE_DATE cont_date sale_date alarm_tm cont_tm sale_tm event_sale
	
	save "${data}\fires\fire_near_event_time"
	
	// Note that this data is "long" in the sense that each observation is a transaction by fire event. A transaction will show up as many times as the number of fire events to which it is relevant. It will be treated as both a treated for an event that happened before it and control for an event that happened after. 
	// Maybe I should add in a dummy variable that indicates whether the control transaction occurred within 3 months after a fire event? For all treated, this would be 0. For true controls, this would be 0. But for a control transaction which occurred.

******************************* Make FHSZ data *******************************
	import excel "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires\FHSZ_merge\main_2018_RR_FHSZ.xlsx", sheet("main_2018_RR_XYTableToPoint_30_") firstrow clear
	
	// Some TransId (1,169 obs) matched with multiple FHSZ 
	
	*If duplicate TransId, keep the one with highest FHSZ risk.
	sort TransId -HAZ_CODE 
	quietly by TransId:  gen FHSZ_dup = cond(_N==1,0,_n)
	drop if FHSZ_dup > 1
	// Could be interesting to check (later) whether homes that are given two different HAZ_CODEs (i.e. get mixed signals about risk) respond any differently
	
	keep TransId FHSZ_dup Join_Count TARGET_FID JOIN_FID SRA INCORP HAZ_CODE HAZ_CLASS
	merge 1:1 TransId using "${data_ztrax}\ztrans_clean\main_2018_RR"
	keep if _m == 3
	drop _m
	
	save "${data}\fires\main_2018_RR_FHSZ"

	
	

