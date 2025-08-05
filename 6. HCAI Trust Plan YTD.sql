/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE FOR PLAN YTD CALCULATIONS

CREATED BY Kirsty Walker 21/11/22
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculate Plan YTD 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_YTD]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_YTD]

Select 
Infection_type
,'Plan YTD' as Measure_Type
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

INTO [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_YTD]


FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly]

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