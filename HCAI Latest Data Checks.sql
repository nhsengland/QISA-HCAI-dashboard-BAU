/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE TO CHECK LATEST AVAILABLE DATA BEFORE RUNNING CODE ON HCAI DASHBOARD TABLES

CREATED BY Kirsty Walker 25/11/22
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Check latest date reflected in tables
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#LatestData') IS NOT NULL 
DROP TABLE #LatestData

SELECT 
	 'CDiff' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data

INTO #LatestData

  FROM [NHSE_UKHF].[HAI].[vw_CDIFF1]

UNION 

SELECT 
     'E.coli' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data
  FROM [NHSE_UKHF].[HAI].[vw_E_Coli1]

UNION 

SELECT 
     'Pseud' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data
  FROM [NHSE_UKHF].[HAI].[vw_P_Aeruginosa_Bacteraemia1]

UNION 

SELECT 
     'Kleb' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data
  FROM [NHSE_UKHF].[HAI].[vw_Klebsiella_Species_Bacteraemia1]

UNION 

SELECT 
     'MRSA' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data
  FROM [NHSE_UKHF].[HAI].[vw_MRSA1]

UNION 

SELECT 
     'MSSA' as Infection_type,
      max([Effective_Snapshot_Date]) as Latest_data
  FROM [NHSE_UKHF].[HAI].[vw_MSSA_Bacteraemia1]

  select *
  from #LatestData
