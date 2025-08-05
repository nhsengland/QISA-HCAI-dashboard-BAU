/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE FOR ACTUAL V PLAN CALCULATIONS

CREATED BY Kirsty Walker 21/11/22
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate Actual v Plan
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_YTD]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_YTD]

SELECT a.Infection_type
      ,'Actual v Plan YTD' as Measure_Type
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

 into [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_YTD]

  FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_YTD] a
  inner join [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_YTD] b on a.Infection_type = b.Infection_type and a.OrgCode = b.OrgCode and a.Date = b.Date