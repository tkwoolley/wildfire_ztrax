* Author: 	Trevor Woolley
* Date:		Jan 20, 2022
* Project:	Fire Risk

********************************************************************************
ssc install tabout

clear
global data_ztrax = "C:\Users\trevor_woolley\ARE_fall2021\SYP\data\ZTRAX"
global gis_data = "C:\Users\trevor_woolley\Documents\ArcGIS\Projects\CA_fires"
global output = "C:\Users\trevor_woolley\ARE_fall2021\SYP\output\"
***************************** Make House char data ***************************
	cd $data
	* Import Asmt data ( obs total)
	import delimited "${data_ztrax}\ZAsmt\Building.txt", bindquote(nobind) clear

	* rename variables
	local var_names "RowID NoOfUnits OccupancyStatusStndCode PropertyCountyLandUseDescription PropertyCountyLandUseCode PropertyLandUseStndCode PropertyStateLandUseDescription PropertyStateLandUseCode BuildingOrImprovementNumber BuildingClassStndCode BuildingQualityStndCode BuildingQualityStndCodeOriginal BuildingConditionStndCode ArchitecturalStyleStndCode YearBuilt EffectiveYearBuilt YearRemodeled NoOfStories TotalRooms TotalBedrooms TotalKitchens FullBath ThreeQuarterBath HalfBath QuarterBath TotalCalculatedBathCount TotalActualBathCount BathSourceStndCode TotalBathPlumbingFixtures RoofCoverStndCode RoofStructureTypeStndCode HeatingTypeorSystemStndCode AirConditioningTypeorSystemStndC FoundationTypeStndCode ElevatorStndCode FireplaceFlag FirePlaceTypeStndCode FireplaceNumber WaterStndCode SewerStndCode MortgageLenderName TimeshareStndCode Comments LoadID StoryTypeStndCode FIPS BatchID"

	local i = 1
	foreach x in `var_names' {
		rename v`i' `x'
		local i = `i' + 1
		}

	drop PropertyStateLandUseDescription PropertyStateLandUseCode ArchitecturalStyleStndCode BuildingConditionStndCode EffectiveYearBuilt YearRemodeled TotalKitchens ThreeQuarterBath QuarterBath TotalBathPlumbingFixtures RoofStructureTypeStndCode FoundationTypeStndCode FirePlaceTypeStndCode MortgageLenderName TimeshareStndCode Comments StoryTypeStndCode

	save "${data_ztrax}\ztrans_clean\housechar"
	
***************************** Make Asmt Main data *****************************
	cd $data
	* Import Asmt data ( obs total)
	import delimited "${data_ztrax}\ZAsmt\Main.txt", bindquote(nobind) clear
	
	* rename variables
	local var_names "RowID ImportParcelID FIPS State County ValueCertDate ExtractDate Edition ZVendorStndCode AssessorParcelNumber DupAPN UnformattedAssessorParcelNumber ParcelSequenceNumber AlternateParcelNumber OldParcelNumber ParcelNumberTypeStndCode RecordSourceStndCode RecordTypeStndCode ConfidentialRecordFlag PropertyAddressSourceStndCode PropertyHouseNumber PropertyHouseNumberExt PropertyStreetPreDirectional PropertyStreetName PropertyStreetSuffix PropertyStreetPostDirectional PropertyFullStreetAddress PropertyCity PropertyState PropertyZip PropertyZip4 OriginalPropertyFullStreetAddr OriginalPropertyAddressLastline PropertyBuildingNumber PropertyZoningDescription PropertyZoningSourceCode CensusTract TaxIDNumber TaxAmount TaxYear TaxDelinquencyFlag TaxDelinquencyAmount TaxDelinquencyYear TaxRateCodeArea LegalLot LegalLotStndCode LegalOtherLot LegalBlock LegalSubdivisionCode LegalSubdivisionName LegalCondoProjectPUDDevName LegalBuildingNumber LegalUnit LegalSection LegalPhase LegalTract LegalDistrict LegalMunicipality LegalCity LegalTownship LegalSTRSection LegalSTRTownship LegalSTRRange LegalSTRMeridian LegalSecTwnRngMer LegalRecordersMapReference LegalDescription LegalNeighborhoodSourceCode NoOfBuildings LotSizeAcres LotSizeSquareFeet LotSizeFrontageFeet LotSizeDepthFeet LotSizeIRR LotSiteTopographyStndCode LoadID PropertyAddressMatchcode PropertyAddressUnitDesignator PropertyAddressUnitNumber PropertyAddressCarrierRoute PropertyAddressGeoCodeMatchCode PropertyAddressLatitude PropertyAddressLongitude PropertyAddressCensusTractAndBl PropertyAddressConfidenceScore PropertyAddressCBSACode PropertyAddressCBSADivisionCode PropertyAddressMatchType PropertyAddressDPV PropertyGeocodeQualityCode PropertyAddressQualityCode SubEdition BatchID BKFSPID SourceChkSum"

	local i = 1
	foreach x in `var_names' {
		rename v`i' `x'
		local i = `i' + 1
		}

	drop DupAPN ParcelNumberTypeStndCode RecordSourceStndCode RecordTypeStndCode ConfidentialRecordFlag CensusTract TaxIDNumber TaxDelinquencyFlag TaxDelinquencyAmount LegalLot LegalLotStndCode LegalOtherLot LegalSubdivisionCode LegalSubdivisionName LegalCondoProjectPUDDevName LegalBuildingNumber LegalUnit LegalSection LegalPhase LegalTract LegalDistrict LegalMunicipality LegalCity LegalTownship LegalSTRSection LegalSTRTownship LegalSTRRange LegalSTRMeridian LegalSecTwnRngMer LegalRecordersMapReference LegalDescription LegalNeighborhoodSourceCode LotSizeFrontageFeet LotSizeDepthFeet LotSizeIRR LotSiteTopographyStndCode LoadID PropertyAddressMatchcode PropertyAddressUnitNumber PropertyAddressCarrierRoute PropertyAddressGeoCodeMatchCode PropertyAddressConfidenceScore PropertyAddressCBSACode PropertyAddressCBSADivisionCode BatchID BKFSPID SourceChkSum

	save "${data_ztrax}\ztrans_clean\asmt_main"

************************* Merge Asmt main and house char **********************
	merge 1:1 RowID using "${data_ztrax}\ztrans_clean\housechar"

	save "${data_ztrax}\ztrans_clean\asmt_main_char" 

******************** Save dataset with just asmt-trans xwalk ******************	
	* Keep only ID and address vars (parcels are unique by AssessorParcelNumber BatchID in Asmt data, but BatchID is not same between Asmt and Trans data)
	* Drop duplicates based on AssessorParcelNumber and Latitude 
	duplicates tag AssessorParcelNumber PropertyAddressLatitude , g(dup2)
	
	preserve
		drop if dup2 > 0
		drop _m
		merge 1:m AssessorParcelNumber PropertyAddressLatitude using "${data_ztrax}\ztrans_clean\main_2018_RR"
		keep RowID TransId AssessorParcelNumber UnformattedAssessorParcelNumber PropertyFullStreetAddr PropertyAddressLatitude PropertyAddressLongitude _merge
		keep if _m ==3 // 1,037,697 obs
		save "${data_ztrax}\merge\xwalk_asmt_trans_RR"
	restore
	
	preserve
		drop if dup2 > 0
		drop _m
		merge 1:m AssessorParcelNumber PropertyAddressLatitude using "${data_ztrax}\ztrans_clean\main_2018_SR"
		keep RowID TransId AssessorParcelNumber UnformattedAssessorParcelNumber PropertyFullStreetAddr PropertyAddressLatitude PropertyAddressLongitude _merge
		keep if _m ==3 // 366,091 obs
		save "${data_ztrax}\merge\xwalk_asmt_trans_SR"
	restore

	
	
	