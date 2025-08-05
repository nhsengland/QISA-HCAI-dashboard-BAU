# Healthcare Associated Infections (HCAI) Dashboard monthly reporting
Repository to store all codes used to process the infections data required for the monthly refresh of the [Healthcare Associated Infections (HCAI) Dashboard](https://future.nhs.uk/Quality/view?objectID=38943952) Tableau product, which is owned by the Quality Improvement Strategic Analysis (QISA) Team and published via the [Quality Analytical Resource Hub](https://future.nhs.uk/Quality/groupHome) FutureNHS workspace.

## About this project
The dashboard summarises the number of healthcare associated infections reported by NHS Acute Trusts by Organisation (and aggregated to ICB and Region) for the following infection types: C. difficile, Gram-negative infections (E. Coli, Klebsiella spp. and Pseudomonas aeruginosa), MRSA and MSSA. Reporting information by infection type includes:
-  Monthly total counts of cases by location of onset, including by metric category.
-  Actuals versus NHS England Standard Contract Thresholds (‘plans’) for C. difficile and Gram-negative infections (there are no plans for MRSA and MSSA).
-  12 month rolling rates per 100,000 bed days, based on actual numbers and quarterly bed days data.

Further information on data reported and methodology is provided within the [HCAI Dashboard](https://future.nhs.uk/Quality/view?objectID=38943952)

Note the code and the Tableau workbook data refresh is currently all run in the National Commissioning Data Repository (NCDR) and will be migrated to the UDAL Data Lake.

## Requirements
-  Access to the NCDR SQL Server Management Studio.
-  For code to be fully reproducible and for access to plan and data output tables, access permissions to the Quality Improvement Strategic Analysis NCDR Sandbox (NHSE_Sandbox_PPMQ_Quality) are also required. For further information, please contact us via england.da-qis-analysis@nhs.net

## Summary of the code	
The code is written in SQL and the SQL scripts require to be run in the below sequential order.
- HCAI Latest Data Checks.sql - Code to check if the latest data is available to run the monthly data refresh.
- 1.HCAI Trust Actual Monthly.sql - Code to obtain the number of infection cases for all infection types and metric categories for Trusts for the latest reporting period and refresh the HCAI_Actual_Monthly output table.
- 2.HCAI Trust 12 Month Rolling Rate Data.sql - Code to obtain denominator data (bed days data) and calculate 12 month rolling rates data and refresh the HCAI_Trust_Rates output table.
- 3.HCAI Trust Plan Data.sql - Code to union individual reporting year plan tables into a combined HCAI_Plan_Monthly output table. The code is run monthly for reflecting any organisational changes.
- 4.HCAI Trust Actual v Plan Monthly.sql - Code to calculate monthly actuals data versus plan variance and refresh the HCAI_Actual_v_Plan_Monthly output table.
- 5.HCAI Trust Actual YTD.sql - Code to calculate YTD actuals data and refresh the HCAI_Actual_YTD output table.
- 6.HCAI Trust Plan YTD.sql - Code to calculate YTD plan data and refresh the HCAI_Plan_YTD output table.
- 7.HCAI Trust Actual v Plan YTD.sql - Code to calculate YTD actuals data versus plan variance and refresh the HCAI_Actual_v_Plan_Monthly output table.
- 8.HCAI Trust Code.sql - Code to combine counts, plan and rates data to refresh the HCAI_Dashboard_Trust_Data final output table for refreshing the Tableau workbook.

Please see the HCAI Tables Flowchart for further information on the output tables refresh process.

## Data sources
-	Infections numerator data:  [UK Health Security Agency (UKHSA) monthly infections published data](https://www.gov.uk/government/statistics/mrsa-mssa-gram-negative-bacteraemia-and-cdi-monthly-data-2024-to-2025)
-	Plan data:  [NHS England Standard Contract Thresholds published data](https://www.england.nhs.uk/publication/minimising-clostridioides-difficile-and-gram-negative-bloodstream-infections/)
-	Rate denominator data:  [NHS England bed availability and occupancy KH03 quarterly collection published data](https://www.england.nhs.uk/statistics/statistical-work-areas/bed-availability-and-occupancy/bed-availability-and-occupancy-kh03/)

## License
Unless stated otherwise, the codebase is released under the MIT LICENSE. This covers both the codebase and any sample code in the documentation.
See [MIT License](https://github.com/nhsengland/QISA-HCAI-dashboard-BAU/blob/main/LICENSE) for more information.
The documentation is © Crown copyright and available under the terms of the Open Government 3.0 licence.

## Author
- Kirsty Walker - contact is via england.da-qis-analysis@nhs.net

## Contact
To get in touch with us and find out more about the Quality Improvement Strategic Analysis Team please email us at england.da-qis-analysis@nhs.net
