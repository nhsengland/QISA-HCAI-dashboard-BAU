/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE FOR ACTUAL YTD CALCULATIONS

CREATED BY Kirsty Walker 18/11/22

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


----- Actual YTD - Trust C. difficle -----

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for C. difficile Trust Actual YTD
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#CDiff_Actual_YTD_Staging') IS NOT NULL 
DROP TABLE #CDiff_Actual_YTD_Staging

Select 
Infection_type
,Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #CDiff_Actual_YTD_Staging

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where Infection_type='C. difficile'
and OrgType='NHS acute trust'
and Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')

group by
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating for C. difficile Trust Actual YTD
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#CDiff_Actual_YTD') IS NOT NULL 
DROP TABLE #CDiff_Actual_YTD

Select 
Infection_type
,'Actual YTD' as Measure_Type
,OrgType
,OrgCode
,Metric
,sum(Measure_Value) over (partition by OrgCode, Financial_Year order by Date) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #CDiff_Actual_YTD

FROM #CDiff_Actual_YTD_Staging

group by
Infection_type
,OrgType
,OrgCode
,Metric
,Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

---- Actual YTD - Trust E.coli, Pseud and Kleb -----

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for E.coli, Pseud and Kleb Trust Actual YTD for counting methodology 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#EPK_Actual_YTD_Staging') IS NOT NULL 
DROP TABLE #EPK_Actual_YTD_Staging

Select 
Infection_type
,Measure_Type
,OrgType
,OrgCode
,CASE WHEN Date>='2021-04-30'
then 'Hospital-onset, healthcare associated and Community-onset, healthcare associated' 
else 'Hospital-onset'
END Metric
,sum(Measure_Value) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #EPK_Actual_YTD_Staging

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where 
(
(Infection_type in ('E. coli', 'Pseudomonas aeruginosa', 'Klebsiella spp')
and Metric in ('Hospital-onset, healthcare associated', 'Community-onset, healthcare associated')
and Date>='2021-04-30')
OR
(Infection_type in ('E. coli', 'Pseudomonas aeruginosa', 'Klebsiella spp')
and Metric='Hospital-onset'
and Date<'2021-04-30')
)
and OrgType='NHS acute trust'

group by
Infection_type
,Measure_Type
,OrgType
,OrgCode
,CASE WHEN Date>='2021-04-30'
then 'Hospital-onset, healthcare associated and Community-onset, healthcare associated' 
else 'Hospital-onset'
END 
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating for E.coli, Pseud and Kleb Trust Actual YTD
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#EPK_Actual_YTD') IS NOT NULL 
DROP TABLE #EPK_Actual_YTD

Select 
Infection_type
,'Actual YTD' as Measure_Type
,OrgType
,OrgCode
,Metric
,sum(Measure_Value) over (partition by Infection_type, OrgCode, Financial_Year order by Date) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #EPK_Actual_YTD

FROM #EPK_Actual_YTD_Staging

group by
Infection_type
,OrgType
,OrgCode
,Metric
,Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

----- Actual YTD - Trust MRSA and MSSA -----

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for MRSA and MSSA Trust Actual YTD
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MM_Actual_YTD_Staging') IS NOT NULL 
DROP TABLE #MM_Actual_YTD_Staging

Select 
Infection_type
,Measure_Type
,OrgType
,OrgCode
,'Hospital-onset, healthcare associated and Community-onset, healthcare associated' as Metric
,sum(Measure_Value) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #MM_Actual_YTD_Staging

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

where Infection_type in ('MRSA','MSSA')
and OrgType='NHS acute trust'
and Metric in ('Hospital-onset, healthcare associated','Community-onset, healthcare associated')

group by
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating for MRSA and MSSA Trust Actual YTD
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MM_Actual_YTD') IS NOT NULL 
DROP TABLE #MM_Actual_YTD

Select 
Infection_type
,'Actual YTD' as Measure_Type
,OrgType
,OrgCode
,Metric
,sum(Measure_Value) over (partition by Infection_type, OrgCode, Financial_Year order by Date) as Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

INTO #MM_Actual_YTD

FROM #MM_Actual_YTD_Staging

group by
Infection_type
,OrgType
,OrgCode
,Metric
,Measure_Value
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

----- Union all data into output table -----

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
UNION Actual YTD data into output table
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_YTD]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_YTD]

Select 
Infection_type collate SQL_Latin1_General_CP1_CI_AS as Infection_type
,Measure_Type collate database_default as Measure_Type
,OrgType collate SQL_Latin1_General_CP1_CI_AS as OrgType
,OrgCode collate database_default as OrgCode
,Metric collate SQL_Latin1_General_CP1_CI_AS as Metric
,Measure_Value 
,Date 
,Financial_Year collate database_default as Financial_Year
,Organisation_Name collate database_default as Organisation_Name
,ICB_Code collate database_default as ICB_Code
,ICB_Name collate database_default as ICB_Name
,Region_Code collate database_default as Region_Code
,Region_Name collate database_default as Region_Name

into [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_YTD]
from #CDiff_Actual_YTD

UNION ALL

Select 
Infection_type collate SQL_Latin1_General_CP1_CI_AS as Infection_type
,Measure_Type collate database_default as Measure_Type
,OrgType collate SQL_Latin1_General_CP1_CI_AS as OrgType
,OrgCode collate database_default as OrgCode
,Metric collate SQL_Latin1_General_CP1_CI_AS as Metric
,Measure_Value 
,Date 
,Financial_Year collate database_default as Financial_Year
,Organisation_Name collate database_default as Organisation_Name
,ICB_Code collate database_default as ICB_Code
,ICB_Name collate database_default as ICB_Name
,Region_Code collate database_default as Region_Code
,Region_Name collate database_default as Region_Name
from #EPK_Actual_YTD

UNION ALL

Select 
Infection_type collate SQL_Latin1_General_CP1_CI_AS as Infection_type
,Measure_Type collate database_default as Measure_Type
,OrgType collate SQL_Latin1_General_CP1_CI_AS as OrgType
,OrgCode collate database_default as OrgCode
,Metric collate SQL_Latin1_General_CP1_CI_AS as Metric
,Measure_Value 
,Date 
,Financial_Year collate database_default as Financial_Year
,Organisation_Name collate database_default as Organisation_Name
,ICB_Code collate database_default as ICB_Code
,ICB_Name collate database_default as ICB_Name
,Region_Code collate database_default as Region_Code
,Region_Name collate database_default as Region_Name
from #MM_Actual_YTD

