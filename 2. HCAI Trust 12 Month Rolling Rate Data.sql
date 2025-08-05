/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE TO OBTAIN TRUST 12 MONTH ROLLING RATE DATA

CREATED BY Kirsty Walker 14/10/22

2024-08-13 Amended by Geoff Sharpe at lines 620 and 754 to add 'Hospital-onset, healthcare associated' to 'Hospital-onset' for MRSA and MSSA following change to reporting.
2024-08-14 Amended by Geoff Sharpe around lines 620 and 754 to add report only 'Hospital-onset, healthcare associated' category for MRSA and MSSA
2025-05-01 Amended by Shalika De Silva lines 614 - 622 and 754 to include Community-onset, healthcare associated catergory to MRSA and MSSA
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


------ 12 MONTH ROLLING RATE - DENOMINATOR STAGING (BED DAYS) -------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for Bed days data, making sure under new providers and repeating quarter data rows 
for each month in quarter
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#BedDays') IS NOT NULL 
DROP TABLE #BedDays

SELECT COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
      ,sum(t1.[Number_Of_Beds]) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
	  ,t3.Date
	  ,DAY(t3.Date) as Days_In_Month
	  ,sum(t1.[Number_Of_Beds])*DAY(t3.Date) as Monthly_Beds

INTO #BedDays
  
FROM [NHSE_UKHF].[Bed_Availability].[vw_Provider_By_Sector_Occupied_Overnight_Beds1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original
Cross Apply ( values (EOMonth(dateadd(MONTH,-2,t1.[Effective_Snapshot_Date])))
                     ,(EOMonth(dateadd(MONTH,-1,t1.[Effective_Snapshot_Date])))
                     ,(EOMonth(dateadd(MONTH,-0,t1.[Effective_Snapshot_Date])))
             ) t3(Date)

group by
COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS),
t1.[Effective_Snapshot_Date],
t3.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Filter on bed days for latest quarter
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#BedDaysLag') IS NOT NULL 
DROP TABLE #BedDaysLag

SELECT COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
      ,sum(t1.[Number_Of_Beds]) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
	  ,t1.[Effective_Snapshot_Date]

	  INTO #BedDaysLag

FROM [NHSE_UKHF].[Bed_Availability].[vw_Provider_By_Sector_Occupied_Overnight_Beds1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original
where Effective_Snapshot_Date=(SELECT MAX([Effective_Snapshot_Date]) FROM [NHSE_UKHF].[Bed_Availability].[vw_Provider_By_Sector_Occupied_Overnight_Beds1])

group by
COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS),
t1.[Effective_Snapshot_Date]

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF C.diff TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#CDiff_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #CDiff_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #CDiff_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')
and Infection_type='C. difficile'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#CDiff_Rate_Numerator') IS NOT NULL
DROP TABLE #CDiff_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #CDiff_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #CDiff_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to Cdiff and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#CDiff_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #CDiff_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #CDiff_Rate_Denominator_Staging

from #CDiff_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the CDiff 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#CDiff_Rate_Denominator') IS NOT NULL
DROP TABLE #CDiff_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #CDiff_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #CDiff_Rate_Denominator_Staging
) x

WHERE rn > 11 

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF E.coli TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Ecoli_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #Ecoli_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #Ecoli_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')
and Infection_type='E. coli'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Ecoli_Rate_Numerator') IS NOT NULL
DROP TABLE #Ecoli_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #Ecoli_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Ecoli_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to Ecoli and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Ecoli_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #Ecoli_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #Ecoli_Rate_Denominator_Staging

from #Ecoli_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the Ecoli 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Ecoli_Rate_Denominator') IS NOT NULL
DROP TABLE #Ecoli_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #Ecoli_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Ecoli_Rate_Denominator_Staging
) x

WHERE rn > 11 

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF Pseud TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Pseud_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #Pseud_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #Pseud_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')
and Infection_type='Pseudomonas aeruginosa'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Pseud_Rate_Numerator') IS NOT NULL
DROP TABLE #Pseud_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #Pseud_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Pseud_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to Pseud and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Pseud_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #Pseud_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #Pseud_Rate_Denominator_Staging

from #Pseud_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the Pseud 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Pseud_Rate_Denominator') IS NOT NULL
DROP TABLE #Pseud_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #Pseud_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Pseud_Rate_Denominator_Staging
) x

WHERE rn > 11 

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF Kleb TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Kleb_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #Kleb_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #Kleb_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')
and Infection_type='Klebsiella spp'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Kleb_Rate_Numerator') IS NOT NULL
DROP TABLE #Kleb_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #Kleb_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Kleb_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to Kleb and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Kleb_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #Kleb_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #Kleb_Rate_Denominator_Staging

from #Kleb_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the Kleb 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#Kleb_Rate_Denominator') IS NOT NULL
DROP TABLE #Kleb_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #Kleb_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #Kleb_Rate_Denominator_Staging
) x

WHERE rn > 11 

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF MRSA TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MRSA_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #MRSA_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #MRSA_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated','Community-onset, healthcare associated')
and Infection_type='MRSA'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MRSA_Rate_Numerator') IS NOT NULL
DROP TABLE #MRSA_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #MRSA_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #MRSA_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to MRSA and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MRSA_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #MRSA_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #MRSA_Rate_Denominator_Staging

from #MRSA_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the MRSA 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MRSA_Rate_Denominator') IS NOT NULL
DROP TABLE #MRSA_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #MRSA_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #MRSA_Rate_Denominator_Staging
) x

WHERE rn > 11 

------ 12 MONTH ROLLING RATE - NUMERATOR (12 MONTH ROLLING HCAI COUNTS) -------
-----	START OF MSSA TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate 12 month rolling rate numerator Staging - filtering out for metric
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MSSA_Rate_Numerator_Staging') IS NOT NULL
DROP TABLE #MSSA_Rate_Numerator_Staging

Select 
Infection_type
,'12 Month Rolling Rate per 100,000 bed days' as Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Numerator_Staging_Value
,Date

INTO #MSSA_Rate_Numerator_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where  Metric in ('Hospital-onset, healthcare associated','Community-onset, healthcare associated')
and Infection_type='MSSA'

group by 
Infection_type
,OrgType
,OrgCode
,Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculate 12 month rolling rate numerator 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MSSA_Rate_Numerator') IS NOT NULL
DROP TABLE #MSSA_Rate_Numerator

Select Infection_type,
Measure_Type, 
OrgType,
OrgCode,
Metric,
Rate_Num,
Date

INTO #MSSA_Rate_Numerator

FROM

(
	SELECT

	*,
	SUM(Numerator_Staging_Value) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Num,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #MSSA_Rate_Numerator_Staging
	
) x

WHERE rn > 11 --At least 12 months as it's 12 month rolling 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Join Bed Days table to MSSA and calc monthly bed days accounting for 
lag between HCAI monthly count data and Quarterly Bed Days data
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MSSA_Rate_Denominator_Staging') IS NOT NULL 
DROP TABLE #MSSA_Rate_Denominator_Staging

Select 
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date) as Days_In_Month
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight) as Average_Daily_Number_Of_Occupied_Beds_Open_Overnight
,sum(ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight))*DAY(a.Date) as Monthly_Beds

INTO #MSSA_Rate_Denominator_Staging

from #MSSA_Rate_Numerator a
left outer join #BedDays b on a.OrgCode COLLATE Latin1_General_CI_AS = b.OrgCode and a.Date = b.Date
left outer join #BedDaysLag c on a.OrgCode COLLATE Latin1_General_CI_AS = c.OrgCode 

group by
a.Infection_type
,a.Measure_Type
,a.OrgType
,a.OrgCode
,a.Metric
,a.Rate_Num
,a.Date
,DAY(a.Date)
,ISNULL(b.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight, c.Average_Daily_Number_Of_Occupied_Beds_Open_Overnight)

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Calculate the denominator for the MSSA 12 month rolling rate - bed day rolling 12 months
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID ('tempdb..#MSSA_Rate_Denominator') IS NOT NULL
DROP TABLE #MSSA_Rate_Denominator

SELECT
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric
,Rate_Num
,Date
,Rate_Den

INTO #MSSA_Rate_Denominator

FROM

(
	SELECT

	*,
	SUM(Monthly_Beds) OVER(PARTITION BY OrgCode ORDER BY Date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rate_Den,
	ROW_NUMBER() OVER (PARTITION BY OrgCode ORDER BY Date  ASC) as RN

	FROM #MSSA_Rate_Denominator_Staging
) x

WHERE rn > 11 

----- 12 MONTH ROLLING RATE CALCULATION AND UNION INTO ONE OUTPUT TABLE (12 MONTH ROLLING HCAI COUNTS) -------

----RATE---

IF OBJECT_ID ('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Trust_Rates]') IS NOT NULL
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Trust_Rates]

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

INTO [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Trust_Rates]

FROM #CDiff_Rate_Numerator a
LEFT JOIN #CDiff_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Ecoli_Rate_Numerator a
LEFT JOIN #Ecoli_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Pseud_Rate_Numerator a
LEFT JOIN #Pseud_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Kleb_Rate_Numerator a
LEFT JOIN #Kleb_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MRSA_Rate_Numerator a
LEFT JOIN #MRSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
a.Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
((a.Rate_Num/b.Rate_Den)*100000) as Rate,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MSSA_Rate_Numerator a
LEFT JOIN #MSSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

---- RATE NUMERATOR FOR AGGREGATING TO ICB AND REGION IN DASHBOARD ---
UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #CDiff_Rate_Numerator a
LEFT JOIN #CDiff_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Ecoli_Rate_Numerator a
LEFT JOIN #Ecoli_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Pseud_Rate_Numerator a
LEFT JOIN #Pseud_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Kleb_Rate_Numerator a
LEFT JOIN #Kleb_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MRSA_Rate_Numerator a
LEFT JOIN #MRSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Numerator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
a.Rate_Num,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MSSA_Rate_Numerator a
LEFT JOIN #MSSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

---- RATE DENOMINATOR FOR AGGREGATING TO ICB AND REGION IN DASHBOARD ---
UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #CDiff_Rate_Numerator a
LEFT JOIN #CDiff_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Ecoli_Rate_Numerator a
LEFT JOIN #Ecoli_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Pseud_Rate_Numerator a
LEFT JOIN #Pseud_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #Kleb_Rate_Numerator a
LEFT JOIN #Kleb_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MRSA_Rate_Numerator a
LEFT JOIN #MRSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'

UNION ALL

Select
a.Infection_type,
'Rate Denominator' as Measure_Type, 
a.OrgType,
a.OrgCode,
a.Metric,
b.Rate_Den,
a.Date,
CASE WHEN MONTH(a.Date) <= 3 THEN convert(varchar(4), YEAR(a.Date)-1) + '/' + convert(varchar(4), YEAR(a.Date)%100)    
ELSE convert(varchar(4),YEAR(a.Date))+ '/' + convert(varchar(4),(YEAR(a.Date)%100)+1) END as Financial_Year,
c.Organisation_Name,
c.STP_Code as ICB_Code,
c.STP_Name as ICB_Name,
c.Region_Code,
c.Region_Name

FROM #MSSA_Rate_Numerator a
LEFT JOIN #MSSA_Rate_Denominator b on a.OrgCode = b.OrgCode and a.Date = b.Date
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as c on a.OrgCode COLLATE DATABASE_DEFAULT = c.Organisation_Code COLLATE DATABASE_DEFAULT
where c.[NHSE_Organisation_Type]='ACUTE TRUST'



