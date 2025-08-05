/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
NHS ACUTE TRUST HEALTHCARE ASSOCIATED INFECTIONS (HCAI) DASHBOARD
CONTACT: Quality Improvement Strategic Analysis team, england.da-qis-analysis@nhs.net

CODE TO OBTAIN TRUST ACTUAL DATA (COUNT DATA)

CREATED BY Kirsty Walker 14/10/22

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


-----	START OF C.diff TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#CDiff_RW6_to_RM3') IS NOT NULL 
DROP TABLE #CDiff_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #CDiff_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_CDIFF1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#CDiff_RW6_to_R0A') IS NOT NULL 
DROP TABLE #CDiff_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #CDiff_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_CDIFF1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#CDiff_Actual_Staging') IS NOT NULL 
DROP TABLE #CDiff_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date 

Into #CDiff_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_CDIFF1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#CDiff_Actual_Staging_2') IS NOT NULL 
DROP TABLE #CDiff_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #CDiff_Actual_Staging_2
from #CDiff_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #CDiff_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #CDiff_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#CDiff_Output') IS NOT NULL 
DROP TABLE #CDiff_Output

Select case when Infection_Type='CDI' then 'C. difficile'
	  else Infection_Type
	  end as Infection_Type
	  ,Measure_type
	  ,OrgType
	  ,OrgCode
	  ,case when Metric='HOHA cases' then 'Hospital-onset, healthcare associated'
	  when Metric='COIA cases' then 'Community-onset, indeterminate association'
	  when Metric='COHA cases' then 'Community-onset, healthcare associated'
	  when Metric='COCA cases' then 'Community-onset, community associated'
	  else Metric
	  end as Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #CDiff_Output

from #CDiff_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST' 

group by Infection_type,
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

-----	START OF E.coli TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Ecoli_RW6_to_RM3') IS NOT NULL 
DROP TABLE #Ecoli_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Ecoli_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_E_Coli1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Ecoli_RW6_to_R0A') IS NOT NULL 
DROP TABLE #Ecoli_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Ecoli_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_E_coli1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Ecoli_Actual_Staging') IS NOT NULL 
DROP TABLE #Ecoli_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date 

Into #Ecoli_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_E_Coli1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Ecoli_Actual_Staging_2') IS NOT NULL 
DROP TABLE #Ecoli_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #Ecoli_Actual_Staging_2
from #Ecoli_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Ecoli_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Ecoli_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region and joining rate numerator
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Ecoli_Output') IS NOT NULL 
DROP TABLE #Ecoli_Output

Select Infection_type
	  ,Measure_Type
	  ,OrgType
	  ,OrgCode
	  ,Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #Ecoli_Output

from #Ecoli_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by Infection_type,
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

-----	START OF Pseud TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Pseud_RW6_to_RM3') IS NOT NULL 
DROP TABLE #Pseud_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Pseud_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_P_Aeruginosa_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Pseud_RW6_to_R0A') IS NOT NULL 
DROP TABLE #Pseud_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Pseud_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_P_Aeruginosa_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Pseud_Actual_Staging') IS NOT NULL 
DROP TABLE #Pseud_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Pseud_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_P_Aeruginosa_Bacteraemia1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Pseud_Actual_Staging_2') IS NOT NULL 
DROP TABLE #Pseud_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #Pseud_Actual_Staging_2
from #Pseud_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Pseud_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Pseud_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Pseud_Output') IS NOT NULL 
DROP TABLE #Pseud_Output

Select Infection_type
	  ,Measure_Type
	  ,OrgType
	  ,OrgCode
	  ,Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #Pseud_Output

from #Pseud_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by Infection_type,
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

-----	START OF Kleb TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Kleb_RW6_to_RM3') IS NOT NULL 
DROP TABLE #Kleb_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Kleb_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_Klebsiella_Species_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Kleb_RW6_to_R0A') IS NOT NULL 
DROP TABLE #Kleb_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #Kleb_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_Klebsiella_Species_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#Kleb_Actual_Staging') IS NOT NULL 
DROP TABLE #Kleb_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date 

Into #Kleb_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_Klebsiella_Species_Bacteraemia1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Kleb_Actual_Staging_2') IS NOT NULL 
DROP TABLE #Kleb_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #Kleb_Actual_Staging_2
from #Kleb_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Kleb_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #Kleb_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#Kleb_Output') IS NOT NULL 
DROP TABLE #Kleb_Output

Select Infection_type
	  ,Measure_Type
	  ,OrgType
	  ,OrgCode
	  ,Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #Kleb_Output

from #Kleb_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by Infection_type,
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

-----	START OF MRSA TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MRSA_RW6_to_RM3') IS NOT NULL 
DROP TABLE #MRSA_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #MRSA_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_MRSA1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MRSA_RW6_to_R0A') IS NOT NULL 
DROP TABLE #MRSA_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #MRSA_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_MRSA1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MRSA_Actual_Staging') IS NOT NULL 
DROP TABLE #MRSA_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #MRSA_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_MRSA1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MRSA_Actual_Staging_2') IS NOT NULL 
DROP TABLE #MRSA_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #MRSA_Actual_Staging_2
from #MRSA_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #MRSA_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #MRSA_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MRSA_Output') IS NOT NULL 
DROP TABLE #MRSA_Output

Select Infection_type
	  ,Measure_Type
	  ,OrgType
	  ,OrgCode
	  ,Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #MRSA_Output

from #MRSA_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by Infection_type,
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

-----	START OF MSSA TRUST infections  ------

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 1 Calculating RW6 to RM3 for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MSSA_RW6_to_RM3') IS NOT NULL 
DROP TABLE #MSSA_RW6_to_RM3

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'RM3' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.71),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #MSSA_RW6_to_RM3

from [NHSE_UKHF].[HAI].[vw_MSSA_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 2 Calculating RW6 to R0A for historic data for 1st October 2021 de-merger
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MSSA_RW6_to_R0A') IS NOT NULL 
DROP TABLE #MSSA_RW6_to_R0A

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,[Organisation_Type] as OrgType
	  ,'R0A' as OrgCode
	  ,[Metric]
      ,CONVERT(INT,ROUND(SUM([Figure]*0.29),0)) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date

Into #MSSA_RW6_to_R0A

from [NHSE_UKHF].[HAI].[vw_MSSA_Bacteraemia1] t1

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code='RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,t1.[Organisation_Code] 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 3 Staging for count data, making sure under new providers
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
IF OBJECT_ID('tempdb..#MSSA_Actual_Staging') IS NOT NULL 
DROP TABLE #MSSA_Actual_Staging

Select Collection as Infection_type
	  ,'Actual' as Measure_Type
	  ,t1.[Organisation_Type] as OrgType
	  ,COALESCE(t2.Prov_Successor, t1.[Organisation_Code] COLLATE Latin1_General_CI_AS) as OrgCode
	  ,[Metric]
      ,sum([Figure]) as Measure_Value
	  ,[Effective_Snapshot_Date] as Date 

Into #MSSA_Actual_Staging

from [NHSE_UKHF].[HAI].[vw_MSSA_Bacteraemia1] t1
LEFT OUTER JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Provider_Successor] t2 on t1.Organisation_Code COLLATE Latin1_General_CI_AS = t2.Prov_original

where t1.Organisation_Type= 'NHS acute trust'
and Organisation_Code<>'RW6'
and t1.Effective_Snapshot_Date>='2018-04-30'

group by t1.Collection
,COALESCE(t2.Prov_Successor, [Organisation_Code] COLLATE Latin1_General_CI_AS) 
,t1.Effective_Snapshot_Date
,t1.Organisation_Type
,t1.Metric

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 4 Union data with RW6 data 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MSSA_Actual_Staging_2') IS NOT NULL 
DROP TABLE #MSSA_Actual_Staging_2

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 

Into #MSSA_Actual_Staging_2
from #MSSA_Actual_Staging

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #MSSA_RW6_to_RM3

UNION ALL

Select 
Infection_type,
Measure_Type,
OrgType,
OrgCode,
Metric,
Measure_Value,
Date 
from #MSSA_RW6_to_R0A

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
STAGE 5  Count data adding hierarchy for ICB and Region
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

IF OBJECT_ID('tempdb..#MSSA_Output') IS NOT NULL 
DROP TABLE #MSSA_Output

Select Infection_type
	  ,Measure_Type
	  ,OrgType
	  ,OrgCode
	  ,Metric
	  ,sum(Measure_Value) as Measure_Value
	  ,Date
	  ,CASE WHEN MONTH(Date) <= 3 THEN convert(varchar(4), YEAR(Date)-1) + '/' + convert(varchar(4), YEAR(Date)%100)    
       ELSE convert(varchar(4),YEAR(Date))+ '/' + convert(varchar(4),(YEAR(Date)%100)+1) END as Financial_Year
	  ,t3.Organisation_Name
	  ,t3.STP_Code as ICB_Code
	  ,t3.STP_Name as ICB_Name
	  ,t3.Region_Code
	  ,t3.Region_Name

Into #MSSA_Output

from #MSSA_Actual_Staging_2 CS
--for getting the hierarchies for ICB and Region
left join [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] as t3 on CS.OrgCode COLLATE DATABASE_DEFAULT = t3.Organisation_Code COLLATE DATABASE_DEFAULT
where t3.[NHSE_Organisation_Type]='ACUTE TRUST'

group by Infection_type,
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

------ UNION ALL TRUST TABLES INTO ONE OUTPUT TABLE ------

IF OBJECT_ID('[NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]') IS NOT NULL 
DROP TABLE [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

Select *

into [NHSE_Sandbox_PPMQ_Quality].[dbo].[HCAI_Actual_Monthly]

from #CDiff_Output

UNION ALL

Select *
from #Ecoli_Output

UNION ALL

Select *
from #Pseud_Output

UNION ALL

Select * 
from #Kleb_Output

UNION ALL

Select *
from #MRSA_Output

UNION ALL

Select *
from #MSSA_Output




