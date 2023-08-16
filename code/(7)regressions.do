* Author: 	Trevor Woolley
* Date:		Jan 26, 2022
* Project:	Fire Risk

******************************************************************************
//ssc install tabout

global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"

use "${data_ztrax}\reg_data_RR_event_study"

********************************* HOUSE CHAR ********************************
	 * Three levels of housing char from most obs to fewest
	 global house_char_1 "LotSizeSquareFeet YearBuilt TotalBedrooms  TotalCalculatedBathCount i.build_quality"
	 global house_char_2 "LotSizeSquareFeet YearBuilt TotalBedrooms TotalCalculatedBathCount i.build_quality NoOfStories i.heating i.aircond"
	 global house_char_3 "LotSizeSquareFeet YearBuilt NoOfStories TotalRooms TotalBedrooms TotalCalculatedBathCount i.build_quality i.heating i.aircond FireplaceNumber i.bath_code"
	 
******************************** REGRESSIONS *********************************
	// Model 1: event study with homogeneous treatment effect
	// Model 1a: event study with FHSZ interaction on treatment
	// Model 1b: event study with distance interaction on treatment

********************************** Model 1 **********************************
	xtset sale_tm
	* City and month-year FE
	xtreg  log_SalesPriceAmount_HPI_HPI io23.event spring summer fall , fe i(city) 
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_1}, fe i(city)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_2}, fe i(city)
	
	* County and month-year FE
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall , fe i(FIPS)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_1}, fe i(FIPS)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_2}, fe i(FIPS)
	
	* Zip and month-year FE
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall , fe i(PropertyZip)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_1}, fe i(PropertyZip)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall ${house_char_2}, fe i(PropertyZip)
	
	* Event and month-year FE
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall , fe i(NEAR_FID)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall   ${house_char_1}, fe i(NEAR_FID)
	xtreg  log_SalesPriceAmount_HPI io23.event spring summer fall  ${house_char_2}, fe i(NEAR_FID)
	
	// I prefer the fire event FE (NEAR_FID) over the others for two reasons: (1) bc it does not double-count transactions and (2) bc it controls fire event characteristics that may be different across fire events.
	
******************** Model 2a - being in a Very High FHSZ v. not *************
	// Controlling for FHS_VH would normalize the omitted period to their own group, whereas not including it compares them to the average of the two
	* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.treat_not_FHSZ spring summer fall ${house_char_1}, fe i(NEAR_FID) //persistent no effect; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.treat_not_FHSZ spring summer fall ${house_char_2}, fe i(NEAR_FID) //persistent no effect but maybe some positive later; + then persistent -
	
	* Separate events (Event and month-year FE; FHSZ_VH dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH FHSZ_VH io23.treat_not_FHSZ spring summer fall ${house_char_1}, fe i(NEAR_FID) //persistent no effect; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH FHSZ_VH io23.treat_not_FHSZ spring summer fall ${house_char_2}, fe i(NEAR_FID) //persistent no effect but maybe some positive later; + then persistent -
	
	* Marginal effect (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.event spring summer fall ${house_char_1} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //persistent +; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.event spring summer fall ${house_char_2} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //persistent +; persistent -
	
		* Marginal effect (Event and month-year FE; FHSZ dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.event FHSZ_VH spring summer fall ${house_char_1} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //persistent +; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH io23.event FHSZ_VH spring summer fall ${house_char_2} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //persistent +; persistent -
	
	* DD (Event and month-year FE) [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_VH FHSZ_VH post_events spring summer fall ${house_char_1} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //+ + - 
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_VH FHSZ_VH post_events spring summer fall ${house_char_2} if HAZ_CODE==0 | HAZ_CODE==3, fe i(NEAR_FID) //+ + -
	
********************* Model 2b - being in a High FHSZ v. not ****************
	* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_H io23.treat_not_FHSZ spring summer fall ${house_char_1}, fe i(NEAR_FID) //persistent +; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ_H io23.treat_not_FHSZ spring summer fall ${house_char_2}, fe i(NEAR_FID) //persistent +; persistent -
	
	* DD (Event and month-year FE) [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_H FHSZ_H post_events spring summer fall ${house_char_1} if HAZ_CODE!=1, fe i(NEAR_FID) //+ + - 
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_H FHSZ_H post_events spring summer fall ${house_char_2} if HAZ_CODE!=1, fe i(NEAR_FID) //+ + -
	
********************** Model 2c - being in a FHSZ v. not *********************
	* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ io23.treat_not_FHSZ spring summer fall ${house_char_1}, fe i(NEAR_FID) //persistent no effect; persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_FHSZ io23.treat_not_FHSZ spring summer fall ${house_char_2}, fe i(NEAR_FID) //persistent no effect but maybe some positive later; + then persistent -
	
	* DD (Event and month-year FE) [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ FHSZ post_events spring summer fall ${house_char_1}, fe i(NEAR_FID) //+ + - 
	xtreg  log_SalesPriceAmount_HPI post_FHSZ FHSZ post_events spring summer fall ${house_char_2}, fe i(NEAR_FID) //+ + -
	
	// It's cool/consistent that the FHSZ discount increases in magnitude as the risk increases.
	
******************** Model 3a - being w/in 1 mile v. not ********************
// Not much stat sig bc not many houses within 1 mile. Mostly looks weak.
	* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) //
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) //
	
	* Separate events (Event and month-year FE; close_1 dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 close_1 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) //
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 close_1 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) //
	
	* Marginal effect (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 io23.event spring summer fall ${house_char_1} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 io23.event spring summer fall ${house_char_2} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //
	
	* Marginal effect (Event and month-year FE; close_1 dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 close_1 io23.event spring summer fall ${house_char_1} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1 close_1 io23.event spring summer fall ${house_char_2} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //
	
	* DD (Event and month-year FE) [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_close_1 close_1 post_events spring summer fall ${house_char_1} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //- + -
	xtreg  log_SalesPriceAmount_HPI post_close_1 close_1 post_events spring summer fall ${house_char_2} if dist_mile > 2 | dist_mile < 1, fe i(NEAR_FID) //- + -
	
******************** Model 3b - being w/in 2 mile v. not *********************
	* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) // weak; + then persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) // weak; + then persistent -
	
	* Separate events (Event and month-year FE;  close_2 dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2  close_2 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) // persistent -; all - (no effect)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2  close_2 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) // weak -; all - (no effect)
	
	* Marginal effect (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2 io23.event spring summer fall ${house_char_1} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) // no clear effect (some + some -); + then weak -
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2 io23.event spring summer fall ${house_char_2} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) // initially - then nothing; + then weak -
	
	* Marginal effect (Event and month-year FE;  close_2 dummy) 
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2  close_2 io23.event spring summer fall ${house_char_1} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) // persistent -; + then nothing
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_2  close_2 io23.event spring summer fall ${house_char_2} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) //- then nothing; + then nothing
	
	* DD (Event and month-year FE) [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_close_2  close_2 post_events spring summer fall ${house_char_1} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) //- + -
	xtreg  log_SalesPriceAmount_HPI post_close_2  close_2 post_events spring summer fall ${house_char_2} if dist_mile > 5 | dist_mile < 2, fe i(NEAR_FID) 
	
******************** Model 3c - being w/in 5 mile v. not *********************
* Separate events (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) // nothin; + then persistent -
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) // nothin; + then persistent -
	
	* Separate events (Event and month-year FE;   close_5 dummy)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5  close_5 io23.treat_not_close spring summer fall ${house_char_1}, fe i(NEAR_FID) // nothing; nothing
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5  close_5 io23.treat_not_close spring summer fall ${house_char_2}, fe i(NEAR_FID) // nothing ; nothing
	
	* Marginal effect (Event and month-year FE)
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5 io23.event spring summer fall ${house_char_1} , fe i(NEAR_FID) // nothing ; + then weak -
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5 io23.event spring summer fall ${house_char_2}, fe i(NEAR_FID) // nothing; + then weak -
	
	* Marginal effect (Event and month-year FE;   close_5 dummy) [[prefer]]
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5  close_5 io23.event spring summer fall ${house_char_1} , fe i(NEAR_FID) //- then nothing ;+ then nothing
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_5  close_5 io23.event spring summer fall ${house_char_2} , fe i(NEAR_FID) //- then nothing; + then nothing
	
	* DD (Event and month-year FE) [[weak]]
	xtreg  log_SalesPriceAmount_HPI post_close_5  close_5 post_events spring summer fall ${house_char_1} , fe i(NEAR_FID) //- + -
	xtreg  log_SalesPriceAmount_HPI post_close_5  close_5 post_events spring summer fall ${house_char_2} , fe i(NEAR_FID) //+ + -
	
	// It's cool/consistent that the proximity fire effect discount (magnitude) increases as homes get closer to the recent fire event. 

**************************** DDD FHSZ x close_2 *****************************
	// Doesn't make sense to include io0.HAZ_CODE or close_1 with the FHSZ x close_1 interaction right?
	
	* Event and month-year FE	
	reghdfe  log_SalesPriceAmount_HPI io23.treat_FHSZ_VH FHSZ_VH post_events dist_miles post_close_2 i.FID ${HC3} ///
	if event_sale > -13 & event_sale < 13 ///
				& fire_num_trans > 1000 ///
				, absorb(`FE' sale_tm) cluster(`FE')
	
	
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1_FHSZ io23.event close_1 spring summer fall ${house_char_1}, fe i(NEAR_FID) //?
	xtreg  log_SalesPriceAmount_HPI io23.treat_close_1_FHSZ io23.event close_1 spring summer fall  ${house_char_2}, fe i(NEAR_FID) //?

	// I'm unable to identify a clear additional effect of being close AND in a FHSZ. Probably due to the fact that I only have 3,000 obs that fit both criteria. 
	
	* DDD FHSZ_VH x close_2 [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_VH_close_2 post_FHSZ_VH post_close_2 FHSZ_VH_close_2 FHSZ_VH close_2 post_events spring summer fall ${house_char_1} , fe i(NEAR_FID) //? + - - + + -
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_VH_close_2 post_FHSZ_VH post_close_2 FHSZ_VH_close_2 FHSZ_VH close_2 post_events spring summer fall ${house_char_2} , fe i(NEAR_FID) //- + ? - + + -
	
	* DDD FHSZ_H x close_2 [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_H_close_2 post_FHSZ_H post_close_2 FHSZ_H_close_2 FHSZ_H close_2 post_events spring summer fall ${house_char_1} , fe i(NEAR_FID) //? + - - + + -
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_H_close_2 post_FHSZ_H post_close_2 FHSZ_H_close_2 FHSZ_H close_2 post_events spring summer fall ${house_char_2} , fe i(NEAR_FID) //- + ? - + + -
	
	* DDD FHSZ x close_2 [[strong]]
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_close_2 post_FHSZ post_close_2 FHSZ_H_close_2 FHSZ close_2 post_events spring summer fall ${house_char_1} , fe i(NEAR_FID) //+ + - - + + -
	xtreg  log_SalesPriceAmount_HPI post_FHSZ_close_2 post_FHSZ post_close_2 FHSZ_H_close_2 FHSZ close_2 post_events spring summer fall ${house_char_2} , fe i(NEAR_FID) //- + ? - + + -
	
	// Current theory is that "post_close" effects are due to scenery changes and post_FHSZ are due to decreased risk
	// The triple diff (I think) is essentially figuring out which effect is stronger for the close x FHSZ homes. 
	
	
********************* Model 5a - Repeat exposure effect *****************
	// Fire event (NEAR_FID) FE doesn't leave many degrees of freedom for this effect since few houses within 10 miles of a given fire event will have experienced a different number of fire events than the other houses. 
	// Also does not make sense to use with io23.event since event_3m_sum is pretty much just a post indicator and event is a complicated post indicator
	
	* FIPS and month-year FE (incremental effect)
	xtreg  log_SalesPriceAmount_HPI event_3m_sum spring summer fall io0.HAZ_CODE dist_miles ${house_char_1}, fe i(FIPS) //-
	xtreg  log_SalesPriceAmount_HPI event_3m_sum spring summer fall io0.HAZ_CODE dist_miles ${house_char_2}, fe i(FIPS) //-
	xtreg  log_SalesPriceAmount_HPI event_3m_sum spring summer fall io0.HAZ_CODE dist_miles ${house_char_3}, fe i(FIPS) //?-

	* FIPS and month-year FE (boulion w/in 3 months or not)
	xtreg  log_SalesPriceAmount_HPI event_3m spring summer fall io0.HAZ_CODE  ${house_char_1}, fe i(FIPS) //-
	xtreg  log_SalesPriceAmount_HPI event_3m spring summer fall io0.HAZ_CODE  ${house_char_2}, fe i(FIPS) //-
	xtreg  log_SalesPriceAmount_HPI event_3m spring summer fall io0.HAZ_CODE  ${house_char_3}, fe i(FIPS) //-
	
***************** Model 5b - Repeat exposure effect x FHSZ *****************
	// Doesn't make sense to include io0.HAZ_CODE with FHSZ interaction
	* FIPS and month-year FE (interaction)
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ event_3m spring summer fall ${house_char_1}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ event_3m spring summer fall ${house_char_2}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ event_3m spring summer fall ${house_char_3}, fe i(FIPS) //- -
	
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ event_3m spring summer fall ${house_char_1}, fe i(FIPS) //- -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ event_3m spring summer fall ${house_char_2}, fe i(FIPS) //- -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ event_3m spring summer fall ${house_char_3}, fe i(FIPS) //- -

*************** Model 5b - Repeat exposure effect x FHSZ_VH *****************
	// Doesn't make sense to include io0.HAZ_CODE with FHSZ interaction
	* FIPS and month-year FE (interaction)
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ_VH event_3m spring summer fall ${house_char_1}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ_VH event_3m spring summer fall ${house_char_2}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_FHSZ_VH event_3m spring summer fall ${house_char_3}, fe i(FIPS) //? -
	
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ_VH event_3m spring summer fall ${house_char_1}, fe i(FIPS) //- -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ_VH event_3m spring summer fall ${house_char_2}, fe i(FIPS) //- -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_FHSZ_VH event_3m spring summer fall ${house_char_3}, fe i(FIPS) //? -
	
*************** Model 5c - Repeat exposure effect x close_1 *****************
	* FIPS and month-year FE (interaction)
	xtreg  log_SalesPriceAmount_HPI event_3m_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_1}, fe i(FIPS) //? -
	xtreg  log_SalesPriceAmount_HPI event_3m_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_2}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_3}, fe i(FIPS) //- -
	
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_1}, fe i(FIPS) //? -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_2}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_1 event_3m io0.HAZ_CODE spring summer fall ${house_char_3}, fe i(FIPS) //? -	
	
*************** Model 5d - Repeat exposure effect x close_2 *****************
	* FIPS and month-year FE (interaction)
	xtreg  log_SalesPriceAmount_HPI event_3m_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_1}, fe i(FIPS) //? -
	xtreg  log_SalesPriceAmount_HPI event_3m_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_2}, fe i(FIPS) //? -
	xtreg  log_SalesPriceAmount_HPI event_3m_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_3}, fe i(FIPS) //? -
	
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_1}, fe i(FIPS) //+ -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_2}, fe i(FIPS) //? -
	xtreg  log_SalesPriceAmount_HPI event_3m_sum_close_2 event_3m io0.HAZ_CODE spring summer fall ${house_char_3}, fe i(FIPS) //? -
	
	
******************************** Model 2e.24 *********************************
	foreach HC in HC0 HC2 HC3 {
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
		
				coefplot (model_1, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(within 2 miles) omitted) ///
				(model_2, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(5-10 miles away) omitted) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(24, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_24m.png", as(png) replace
			}
		}
	}		
	
******************************** Model 2e.18 ********************************
	foreach HC in HC0 HC2 HC3 {
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
		
				coefplot (model_1, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(within 2 miles) omitted) ///
				(model_2, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 o.event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 ) label(5-10 miles away) omitted) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices  (near and far)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(18, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\close\model_2e_`HC'_`FE'_`treat'_18m.png", as(png) replace
			}
		}
	}				
	
	
******************************** Model 1e.24 *********************************
	foreach HC in HC0 HC2 HC3  {
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
				
				coefplot (model_1, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(very high FHSZ) omitted) ///
				(model_2, keep(event_lead24 event_lead23 event_lead22 event_lead21 event_lead20 event_lead19 event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18 event_lag19 event_lag20 event_lag21 event_lag22 event_lag23 event_lag24) label(not in FHSZ) omitted) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices (by fire risk)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(24, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_24m.png", as(png) replace
			}
		}
	}	

******************************** Model 1e.18 *********************************
	foreach HC in HC0 HC2 HC3 {
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
				
				coefplot (model_1, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(very high FHSZ) omitted) ///
				(model_2, keep(event_lead18 event_lead17 event_lead16 event_lead15 event_lead14 event_lead13 event_lead12 event_lead11 event_lead10 event_lead9 event_lead8 event_lead7 event_lead6 event_lead5 event_lead4 event_lead3 event_lead2 event_lead1 event_0 event_lag1 event_lag2 event_lag3 event_lag4 event_lag5 event_lag6 event_lag7 event_lag8 event_lag9 event_lag10 event_lag11 event_lag12 event_lag13 event_lag14 event_lag15 event_lag16 event_lag17 event_lag18) label(not in FHSZ) omitted) ///
				, vertical title( "{stSerif:{it:Log House Sale Prices (by fire risk)}}", color(black) size(large)) ///
				xtitle("{stSerif:Months Since Fire Event}") xscale(titlegap(2)) xline(0, lcolor(black)) ///
				xline(18, lwidth(thin) lpattern(dash) lcolor(black)) ///
				graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white)  ilwidth(vvvthin)) ///
				//ciopts(lwidth(*2) lcolor(navy)) mcolor(navy)

				graph export "${figures}\event_study\FHSZ\model_1e_`HC'_`FE'_`treat'_18m.png", as(png) replace
			}
		}
	}
	
		
	
	
*********************************** NEXT STEPS ****************************	
	*1) Try changing the event study to only be treated if close, counting everyone else within 10 miles of the event as not treated at all (didn't find anything)
	*2) Make simple time series graphs for key variables
	*3) Make DD tables (2) and DDD table (1)
	*3) Make sum stat tables (2) for final samples
	*5) Connect this to Bayesian learning: How does this effect changes as homes experience more fire events within 3 (6, 12) months before purchase?
	*6) Connect the price effect to market fundamentals (model supply & demand or auction?)
	*7) Run the event study separately by fire event so see distribution of results
	*8) Read literature, especially the Bayesian updating flood insurance paper
	*9) Get estimate of total amount of momey "wasted" by the discounts. 
	*10) could also try to control for the baseline event effect by including a simple post indicator instead of event time?
	