/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE TO OBTAN TRUST PLAN DATA

CREATED BY Kirsty Walker 14/10/22

2025-06-05 Amended by Joanne Slee lines 303 - 373 to add 25_26 PLAN DATA
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


------ ADD 21_22 PLAN DATA ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for 21_22 Plan data, making sure under new providers
(RW6 done prior to load)
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_21_22_Staging') IS NOT NULL 
DROP TABLE #Plan_21_22_Staging

Select InfectionType 
	  ,Measure_Type
	  ,OrgType
	  ,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS)  as OrgCode
	  ,Metric
      ,sum([Measure_Value]) as Measure_Value
	  ,Date 

Into #Plan_21_22_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[21_22_HCAI_Thresholds_by_Month_Division] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.OrgCode COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.OrgType= 'NHS acute trust'

group by t1.InfectionType
,t1.Measure_Type
,t1.OrgType
,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS) 
,t1.Metric
,t1.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2  21_22 Plan data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_21_22') IS NOT NULL 
DROP TABLE #Plan_21_22

Select InfectionType COLLATE SQL_Latin1_General_CP1_CI_AS as Infection_type
	  ,Measure_Type
	  ,OrgType COLLATE SQL_Latin1_General_CP1_CI_AS as OrgType
	  ,OrgCode
	  ,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name COLLATE Latin1_General_CI_AS as Organisation_Name
	  ,t3.STP_Code COLLATE Latin1_General_CI_AS as ICB_Code
	  ,t3.STP_Name COLLATE Latin1_General_CI_AS as ICB_Name
	  ,t3.Region_Code COLLATE Latin1_General_CI_AS as Region_Code
	  ,t3.Region_Name COLLATE Latin1_General_CI_AS as Region_Name

Into #Plan_21_22

from #Plan_21_22_Staging PS
--for getting the hierarchies for STP and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on PS.OrgCode COLLATE Latin1_General_CI_AS = t3.Organisation_Code 
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by InfectionType,
Measure_Type,
OrgType,
OrgCode, 
Metric,
Date,
Organisation_Name,
STP_Code,
STP_Name,
Region_Code,
Region_Name

------ ADD 22_23 PLAN DATA ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for 22_23 Plan data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Plan_22_23_Staging') IS NOT NULL 
DROP TABLE #Plan_22_23_Staging

Select InfectionType
	  ,Measure_Type
	  ,OrgType
	  ,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS)  as OrgCode
	  ,Metric
      ,sum([Measure_Value]) as Measure_Value
	  ,Date 

Into #Plan_22_23_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[22_23_HCAI_Thresholds_by_Month_Division] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.OrgCode COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.OrgType= 'NHS acute trust'

group by t1.InfectionType
,t1.Measure_Type
,t1.OrgType
,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS) 
,t1.Metric
,t1.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2  22_23 Plan data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_22_23') IS NOT NULL 
DROP TABLE #Plan_22_23

Select InfectionType COLLATE SQL_Latin1_General_CP1_CI_AS as Infection_type
	  ,Measure_Type
	  ,OrgType COLLATE SQL_Latin1_General_CP1_CI_AS as OrgType
	  ,OrgCode
	  ,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name 
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code 
	  ,t3.Region_Name 

Into #Plan_22_23

from #Plan_22_23_Staging PS
--for getting the hierarchies for STP and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on PS.OrgCode COLLATE Latin1_General_CI_AS = t3.Organisation_Code 
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by InfectionType,
Measure_Type,
OrgType,
OrgCode, 
Metric,
Date,
Organisation_Name,
STP_Code,
STP_Name,
Region_Code,
Region_Name

------ ADD 23_24 PLAN DATA ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for 23_24 Plan data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Plan_23_24_Staging') IS NOT NULL 
DROP TABLE #Plan_23_24_Staging

Select InfectionType
	  ,Measure_Type
	  ,OrgType
	  ,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS)  as OrgCode
	  ,Metric
      ,sum([Measure_Value]) as Measure_Value
	  ,Date 

Into #Plan_23_24_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[23_24_HCAI_Thresholds_by_Month_Division] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.OrgCode COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.OrgType= 'NHS acute trust'

group by t1.InfectionType
,t1.Measure_Type
,t1.OrgType
,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS) 
,t1.Metric
,t1.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2  23_24 Plan data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_23_24') IS NOT NULL 
DROP TABLE #Plan_23_24

Select InfectionType COLLATE SQL_Latin1_General_CP1_CI_AS as Infection_type
	  ,Measure_Type
	  ,OrgType COLLATE SQL_Latin1_General_CP1_CI_AS as OrgType
	  ,OrgCode
	  ,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name 
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code 
	  ,t3.Region_Name 

Into #Plan_23_24

from #Plan_23_24_Staging PS

--for getting the hierarchies for STP and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on PS.OrgCode COLLATE Latin1_General_CI_AS = t3.Organisation_Code 
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by InfectionType,
Measure_Type,
OrgType,
OrgCode, 
Metric,
Date,
Organisation_Name,
STP_Code,
STP_Name,
Region_Code,
Region_Name


------ ADD 24_25 PLAN DATA ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for 24_25 Plan data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Plan_24_25_Staging') IS NOT NULL 
DROP TABLE #Plan_24_25_Staging

Select InfectionType
	  ,Measure_Type
	  ,OrgType
	  ,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS)  as OrgCode
	  ,Metric
      ,sum([Measure_Value]) as Measure_Value
	  ,Date 

Into #Plan_24_25_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[24_25_HCAI_Thresholds_by_Month_Division] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.OrgCode COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.OrgType= 'NHS acute trust'

group by t1.InfectionType
,t1.Measure_Type
,t1.OrgType
,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS) 
,t1.Metric
,t1.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2  24_25 Plan data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_24_25') IS NOT NULL 
DROP TABLE #Plan_24_25

Select InfectionType COLLATE SQL_Latin1_General_CP1_CI_AS as Infection_type
	  ,Measure_Type
	  ,OrgType COLLATE SQL_Latin1_General_CP1_CI_AS as OrgType
	  ,OrgCode
	  ,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name 
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code 
	  ,t3.Region_Name 

Into #Plan_24_25

from #Plan_24_25_Staging PS

--for getting the hierarchies for STP and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on PS.OrgCode COLLATE Latin1_General_CI_AS = t3.Organisation_Code 
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by InfectionType,
Measure_Type,
OrgType,
OrgCode, 
Metric,
Date,
Organisation_Name,
STP_Code,
STP_Name,
Region_Code,
Region_Name


------ ADD 25_26 PLAN DATA ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Staging for 25_26 Plan data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Plan_25_26_Staging') IS NOT NULL 
DROP TABLE #Plan_25_26_Staging

Select InfectionType
	  ,Measure_Type
	  ,OrgType
	  ,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS)  as OrgCode
	  ,Metric
      ,sum([Measure_Value]) as Measure_Value
	  ,Date 

Into #Plan_25_26_Staging

from [NHSE_Sandbox_PPMQ_Quality].[dbo].[25_26_HCAI_Thresholds_by_Month_Division] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.OrgCode COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.OrgType= 'NHS acute trust'

group by t1.InfectionType
,t1.Measure_Type
,t1.OrgType
,COALESCE(t2.Prov_Successor, t1.OrgCode COLLATE Latin1_General_CI_AS) 
,t1.Metric
,t1.Date

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2  25_26 Plan data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Plan_25_26') IS NOT NULL 
DROP TABLE #Plan_25_26

Select InfectionType COLLATE SQL_Latin1_General_CP1_CI_AS as Infection_type
	  ,Measure_Type
	  ,OrgType COLLATE SQL_Latin1_General_CP1_CI_AS as OrgType
	  ,OrgCode
	  ,Metric COLLATE SQL_Latin1_General_CP1_CI_AS as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name 
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code 
	  ,t3.Region_Name 

Into #Plan_25_26

from #Plan_25_26_Staging PS

--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on PS.OrgCode COLLATE Latin1_General_CI_AS = t3.Organisation_Code 
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by InfectionType,
Measure_Type,
OrgType,
OrgCode, 
Metric,
Date,
Organisation_Name,
STP_Code,
STP_Name,
Region_Code,
Region_Name

------ UNION ALL PLAN DATA INTO ONE OUTPUT TABLE ------

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly]

Select *

into [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Plan_Monthly]

from #Plan_21_22

UNION ALL

Select *
from #Plan_22_23

UNION All

Select *
from #Plan_23_24

UNION All

Select *
from #Plan_24_25

UNION All

Select *
from #Plan_25_26
