/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE FOR ACTUAL v PLAN MONTHLY CALCULATIONS

CREATED BY Kirsty Walker 21/11/22
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Filter out for plan counting methodology
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Actual') IS NOT NULL 
DROP TABLE #Actual

SELECT Infection_type
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

 into #Actual

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly] 

where 
Infection_type in ('C. difficile','E. coli', 'Pseudomonas aeruginosa', 'Klebsiella spp')
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
STAGE 2 Calculate Actual v Plan Monthly
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_Monthly]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_Monthly]

SELECT a.Infection_type
      ,'Actual v Plan Monthly' as Measure_Type
      ,a.OrgType
      ,a.OrgCode
      ,a.Metric
	  ,a.Measure_Value-b.Measure_Value as Measure_Value
      ,a.Date
      ,a.Financial_Year
      ,a.Organisation_Name
      ,a.ICB_Code
      ,a.ICB_Name
      ,a.Region_Code
      ,a.Region_Name

 into [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_Monthly]

  FROM #Actual a
  inner join [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly] b on a.Infection_type = b.Infection_type and a.OrgCode = b.OrgCode and a.Date = b.Date
