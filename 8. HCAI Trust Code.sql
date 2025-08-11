/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE FOR CREATING THE COMBINED TRUST OUTPUT TABLE FOR COUNT, PLAN AND RATE DATa

CREATED BY Kirsty Walker 14/10/22

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Create the combined count, plan and rate data output
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Dashboard_Trust_Data]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Dashboard_Trust_Data] 

Select 
Infection_type
,Measure_Type
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

INTO [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Dashboard_Trust_Data]

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select 
Infection_type
,Measure_Type
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

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select 
Infection_type
,Measure_Type
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

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_Monthly]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select 
Infection_type
,Measure_Type
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

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_YTD]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select 
Infection_type
,Measure_Type
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

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_YTD]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select 
Infection_type
,Measure_Type
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

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_v_Plan_YTD]

WHERE Financial_Year in ('2020/21','2021/22','2022/23','2023/24','2024/25','2025/26')

UNION ALL

Select
Infection_type
,Measure_Type
,OrgType
,OrgCode
,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
,Rate
,Date
,Financial_Year
,Organisation_Name
,ICB_Code
,ICB_Name
,Region_Code
,Region_Name

FROM [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Trust_Rates]


WHERE Financial_Year in ('2021/22','2022/23','2023/24','2024/25','2025/26')
