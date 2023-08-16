* Author: 	Trevor Woolley
* Date:		Nov 2, 2021
* Project:	Fire Risk


********************************************************************************
ssc install tabout

clear
global data = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data"
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires\ztrax"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
******************************** Make Main data ******************************
	cd $data
	* Import trans data (83,432,620 obs total)
	import delimited "${data_ztrax}\ZTrans\Main.txt", bindquote(nobind) clear

	keep if v25 != . // 65,461,315 dropped
	gen ymd = date(v7, "YMD")
	gen year = year(ymd)
	keep if year > 2015 // 14,720,212 dropped

	* rename variables
	local var_names "TransId FIPS State County DataClassStndCode RecordTypeStndCode RecordingDate RecordingDocumentNumber RecordingBookNumber RecordingPageNumber ReRecordedCorrectionStndCode PriorRecordingDate PriorDocumentDate PriorDocumentNumber PriorBookNumber PriorPageNumber DocumentTypeStndCode DocumentDate SignatureDate EffectiveDate BuyerVestingStndCode BuyerMultiVestingFlag PartialInterestTransferStndCode PartialInterestTransferPercent SalesPriceAmount SalesPriceAmountStndCode CityTransferTax CountyTransferTax StateTransferTax TotalTransferTax IntraFamilyTransferFlag TransferTaxExemptFlag PropertyUseStndCode AssessmentLandUseStndCode OccupancyStatusStndCode LegalStndCode BorrowerVestingStndCode LenderName LenderTypeStndCode LenderIDStndCode LenderDBAName DBALenderTypeStndCode DBALenderIDStndCode LenderMailCareOfName LenderMailHouseNumber LenderMailHouseNumberExt LenderMailStreetPreDirectional LenderMailStreetName LenderMailStreetSuffix LenderMailStreetPostDirectional LenderMailFullStreetAddress LenderMailBuildingName LenderMailBuildingNumber LenderMailUnitDesignator LenderMailUnit LenderMailCity LenderMailState LenderMailZip LenderMailZip4 LoanAmount LoanAmountStndCode MaximumLoanAmount LoanTypeStndCode LoanTypeClosedOpenEndStndCode LoanTypeFutureAdvanceFlag LoanTypeProgramStndCode LoanRateTypeStndCode LoanDueDate LoanTermMonths LoanTermYears InitialInterestRate ARMFirstAdjustmentDate ARMFirstAdjustmentMaxRate ARMFirstAdjustmentMinRate ARMIndexStndCode ARMAdjustmentFrequencyStndCode ARMMargin ARMInitialCap ARMPeriodicCap ARMLifetimeCap ARMMaxInterestRate ARMMinInterestRate InterestOnlyFlag InterestOnlyTerm PrepaymentPenaltyFlag PrepaymentPenaltyTerm BiWeeklyPaymentFlag AssumabilityRiderFlag BalloonRiderFlag CondominiumRiderFlag PlannedUnitDevelopmentRiderFlag SecondHomeRiderFlag OneToFourFamilyRiderFlag ConcurrentMtgeDocOrBkPg LoanNumber MERSMINNumber CaseNumber MERSFlag TitleCompanyName TitleCompanyIDStndCode AccommodationRecordingFlag UnpaidBalance InstallmentAmount InstallmentDueDate TotalDelinquentAmount DelinquentAsOfDate CurrentLender CurrentLenderTypeStndCode CurrentLenderIDStndCode TrusteeSaleNumber AttorneyFileNumber AuctionDate AuctionTime AuctionFullStreetAddress AuctionCityName StartingBid KeyedDate KeyerID SubVendorStndCode ImageFileName BuilderFlag MatchStndCode REOStndCode UpdateOwnershipFlag LoadID StatusInd TransactionTypeStndCode BatchID BKFSPID ZVendorStndCode SourceChkSum"

	local i = 1
	foreach x in `var_names' {
		rename v`i' `x'
		local i = `i' + 1
	}

	drop RecordingBookNumber RecordingPageNumber ReRecordedCorrectionStndCode PriorRecordingDate PriorDocumentDate PriorDocumentNumber PriorBookNumber PriorPageNumber BuyerVestingStndCode BuyerMultiVestingFlag PartialInterestTransferStndCode PartialInterestTransferPercent StateTransferTax TotalTransferTax LegalStndCode BorrowerVestingStndCode LenderDBAName DBALenderTypeStndCode DBALenderIDStndCode LenderMailCareOfName LenderMailHouseNumber LenderMailHouseNumberExt LenderMailStreetPreDirectional LenderMailStreetName LenderMailStreetSuffix LenderMailStreetPostDirectional LenderMailFullStreetAddress LenderMailBuildingName LenderMailBuildingNumber LenderMailUnitDesignator LenderMailUnit LenderMailCity LenderMailState LenderMailZip LenderMailZip4 LoanAmountStndCode MaximumLoanAmount LoanTypeStndCode LoanTypeClosedOpenEndStndCode LoanTypeFutureAdvanceFlag LoanTypeProgramStndCode LoanTermMonths LoanTermYears ARMFirstAdjustmentDate ARMFirstAdjustmentMaxRate ARMFirstAdjustmentMinRate ARMIndexStndCode ARMAdjustmentFrequencyStndCode ARMMargin ARMInitialCap ARMPeriodicCap ARMLifetimeCap ARMMaxInterestRate ARMMinInterestRate InterestOnlyFlag InterestOnlyTerm PrepaymentPenaltyFlag PrepaymentPenaltyTerm BiWeeklyPaymentFlag AssumabilityRiderFlag BalloonRiderFlag CondominiumRiderFlag SecondHomeRiderFlag OneToFourFamilyRiderFlag ConcurrentMtgeDocOrBkPg LoanNumber MERSMINNumber CaseNumber MERSFlag TitleCompanyIDStndCode AccommodationRecordingFlag UnpaidBalance InstallmentAmount InstallmentDueDate TotalDelinquentAmount DelinquentAsOfDate CurrentLender CurrentLenderTypeStndCode CurrentLenderIDStndCode TrusteeSaleNumber AttorneyFileNumber AuctionTime ImageFileName BuilderFlag REOStndCode StatusInd TransactionTypeStndCode


	save "${data_ztrax}\ztrans_clean\main"
	
******************************* Add lat/long data ****************************
	* Import Property Info data (86,667,894 obs total)
	import delimited "${data_ztrax}\ZTrans\PropertyInfo.txt", bindquote(nobind) clear
// 	import delimited "${data_ztrax}\ZAsmt\Main.txt", bindquote(nobind) clear
	
	local var_names2 "TransId AssessorParcelNumber APNIndicatorStndCode TaxIDNumber TaxIDIndicatorStndCode UnformattedAssessorParcelNumber AlternateParcelNumber HawaiiCondoCPRCode PropertyHouseNumber PropertyHouseNumberExt PropertyStreetPreDirectional PropertyStreetName PropertyStreetSuffix PropertyStreetPostDirectional PropertyBuildingNumber PropertyFullStreetAddress PropertyCity PropertyState PropertyZip PropertyZip4 OriginalPropertyFullStreetAddr OriginalPropertyAddressLastline PropertyAddressStndCode LegalLot LegalOtherLot LegalLotCode LegalBlock LegalSubdivisionName LegalCondoProjectPUDDevName LegalBuildingNumber LegalUnit LegalSection LegalPhase LegalTract LegalDistrict LegalMunicipality LegalCity LegalTownship LegalSTRSection LegalSTRTownship LegalSTRRange LegalSTRMeridian LegalSecTwnRngMer LegalRecordersMapReference LegalDescription LegalLotSize PropertySequenceNumber PropertyAddressMatchcode PropertyAddressUnitDesignator PropertyAddressUnitNumber PropertyAddressCarrierRoute PropertyAddressGeoCodeMatchCode PropertyAddressLatitude PropertyAddressLongitude PropertyAddressCensusTractAndBl PropertyAddressConfidenceScore PropertyAddressCBSACode PropertyAddressCBSADivisionCode PropertyAddressMatchType PropertyAddressDPV PropertyGeocodeQualityCode PropertyAddressQualityCode FIPS LoadID ImportParcelID BKFSPID AssessmentRecordMatchFlag BatchID"
	
	local i = 1
	foreach x in `var_names2' {
		rename v`i' `x'
		local i = `i' + 1
	}
	
	drop APNIndicatorStndCode TaxIDNumber TaxIDIndicatorStndCode AlternateParcelNumber HawaiiCondoCPRCode PropertyHouseNumber PropertyHouseNumberExt PropertyStreetPostDirectional PropertyBuildingNumber  PropertyAddressStndCode LegalCondoProjectPUDDevName LegalBuildingNumber LegalUnit LegalSection LegalPhase LegalDistrict LegalMunicipality LegalTownship LegalSTRSection LegalSTRTownship LegalSTRRange LegalSTRMeridian LegalSecTwnRngMer PropertyAddressConfidenceScore PropertyAddressCBSACode PropertyAddressCBSADivisionCode
		
	merge m:1 TransId using "${data_ztrax}\ztrans_clean\main", gen(merge_1)
	
	sum merge_1
	drop if merge_1 == 1 // dropped like 8 million
	
	save "${data_ztrax}\ztrans_clean\main_prop", replace
	
******************************* Summary of data ******************************
	
	gen month = month(ymd)
	
	levelsof SalesPriceAmountStndCode, local(level)
	foreach x of local level {
	    disp "****** `x' ********"
	    sum SalesPriceAmount if PropertyUseStndCode == "SR" & IntraFamilyTransferFlag == "" & SalesPriceAmountStndCode == "`x'"
	}
	
* Selecting Final sample
	* Only really care about SR, PD, and CD
	sum SalesPriceAmount if  AssessmentRecordMatchFlag == 1 & PropertyUseStndCode == "SR"  & SalesPriceAmountStndCode != "" & PropertyAddressGeoCodeMatchCode == "Y" 
	
		sum SalesPriceAmount if PropertyUseStndCode == "SR"  & SalesPriceAmountStndCode != "" 
		
	* AssessmentLandUseStndCode has fewer missings than PropertyUseStndCode
	forvalues x = 2016/2021 {
	    disp "`x'"
	    count if PropertyUseStndCode == "" & year == `x'
		count if AssessmentLandUseStndCode == "" & year == `x'		
	}
	
	// Most reliable SalesPriceAmount are when SalesPriceAmountStndCode != 	
	
	* PropertyAddressStndCode become more missing after 2018
	forvalues x = 2016/2021 {
	    disp "`x'"
	    tab PropertyUseStndCode if year == `x'
		count if PropertyUseStndCode == "" & year == `x'		
	}
	
	forvalues x = 2016/2021 {
	    disp "`x'"
		sum SalesPriceAmount if PropertyUseStndCode != "" & year == `x'		
		sum SalesPriceAmount if PropertyUseStndCode == "" & year == `x'		
	}
	
	* Geocode match indicators become more missing after 2018
	forvalues x = 2016/2021 {
	    disp "`x'"
		tab PropertyAddressGeoCodeMatchCode if year == `x'
		count if PropertyAddressGeoCodeMatchCode == "" & year == `x'
	}
	
	* Many obs missing PropertyAddressGeoCodeMatchCode actually do have a lat and long coordinates. In particular after 2017
	forvalues x = 2016/2021 {
	    disp "`x'"
		count if PropertyAddressGeoCodeMatchCode == "" & year == `x'
		count if PropertyAddressGeoCodeMatchCode == "" & PropertyAddressLatitude !=. & PropertyAddressLongitude != . & year == `x'
	}
	// May want to use all addresses with lat and long to get 2019-2021
	
	* Assessment matching does not drop off at all
	forvalues x = 2016/2021 {
	    disp "`x'"
	    tab AssessmentRecordMatchFlag if year == `x'
		count if AssessmentRecordMatchFlag == . & year == `x'		
	}
	
	* AssessmentLandUseStndCode > "RR000" & AssessmentLandUseStndCode < "TR104" and PropertyUseStndCode == "SR" are basically the same but ASSMT has more obs
	count if AssessmentLandUseStndCode > "RR000" & PropertyUseStndCode == "SR"
	count if PropertyUseStndCode == "SR"
	
	// Final data should have AssessmentRecordMatchFlag ==1 
	// Other indicators like SalesPriceAmountStndCode, PropertyUseStndCode,
	// and PropertyAddressGeoCodeMatchCode should be kept in data but used 
	// as robustness checks in analysis. There may be ways to check if SR just
	// using the assessment data. I'll make "safe" data using 2016-2018 and
	// then maybe try the rest later
	
	* Create a "sale date" as signing date or document date if no signing date available
	gen sale_date = SignatureDate
	replace sale_date = DocumentDate if sale_date == ""
	
	gen ymd_sale = date(sale_date, "YMD")
	gen year_sale = year(ymd_sale)
	
****************** Make "safe" sub-sample for just 2016-2018 *****************
	* Drop transactions that are of multiple properties bundled into one transaction
	duplicates tag TransId, g(dup)
	drop if dup > 0
	drop dup
	
	preserve
		keep TransId AssessorParcelNumber UnformattedAssessorParcelNumber  BatchID PropertyFullStreetAddr PropertyAddressLatitude PropertyAddressLongitude RecordingDate sale_date ymd ymd_sale year_sale SalesPriceAmount PropertyAddressGeoCodeMatchCode PropertyGeocodeQualityCode AssessmentLandUseStndCode PropertyUseStndCode SalesPriceAmountStndCode
		keep if year_sale < 2019 & PropertyUseStndCode == "SR"  & SalesPriceAmountStndCode != "" 
		save "${data_ztrax}\ztrans_clean\main_2018_SR", replace 
		
		gen X = PropertyAddressLongitude
		gen Y = PropertyAddressLatitude
		keep TransId AssessorParcelNumber UnformattedAssessorParcelNumber sale_date X Y
		export delimited using "${gis_data}\ztrans_clean\main_2018_SR.csv"
	restore
	
	preserve
		keep TransId AssessorParcelNumber UnformattedAssessorParcelNumber  BatchID PropertyFullStreetAddr PropertyAddressLatitude PropertyAddressLongitude RecordingDate sale_date ymd ymd_sale year_sale SalesPriceAmount PropertyAddressGeoCodeMatchCode PropertyGeocodeQualityCode AssessmentLandUseStndCode PropertyUseStndCode SalesPriceAmountStndCode
		keep if year_sale < 2019 & AssessmentLandUseStndCode > "RR000" & AssessmentLandUseStndCode < "TR104"  & SalesPriceAmountStndCode != "" 
		save "${data_ztrax}\ztrans_clean\main_2018_RR", replace
		
		gen X = PropertyAddressLongitude
		gen Y = PropertyAddressLatitude
		keep TransId AssessorParcelNumber UnformattedAssessorParcelNumber sale_date X Y
		export delimited using "${gis_data}\main_2018_RR.csv"
	restore
	


	