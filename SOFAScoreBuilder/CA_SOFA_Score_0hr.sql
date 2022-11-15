If(OBJECT_ID('tempdb..#Temp0HourO2sat') Is Not Null) Begin Drop Table #Temp0HourO2sat End



CREATE TABLE #Temp0HourO2sat (StudyId int, FlowFIO2 decimal(18,2), fio2_0 decimal(18,2), Flow_Time DateTime, Fio2_Time DateTime)

INSERT INTO #Temp0HourO2sat (StudyId, FlowFIO2, fio2_0, Flow_Time, Fio2_Time)

select CA.StudyId, (21 + o2flow_0*3)/100 as FlowFIO2, fio2_0, Flow_Time, Fio2_Time

from CA

--O2 Flow

left join (
	select CA.StudyId, Time as Flow_Time, CAST(Value/1000 as decimal(18,2)) as o2flow_0,

	row_number() over(partition by CA.StudyId order by Time desc) as O2Flow_Rownumber

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID

	--Added O2 Sat query to use the SAT_Time before the RN limiter

	join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_0,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	where ParameterID = 277
	and Time <= DATEADD(hh,12,ROSC)
	) as o2sat_0 on CA.StudyId = o2sat_0.StudyId
	and O2sat_RN = 1

	and ParameterID in ( '3834', '7287', '7582')
	and Time <= DATEADD(hh,12,ROSC)
	and Time <= Sat_Time
	) as o2flow_0 on CA.StudyId = o2flow_0.StudyId
	and O2Flow_Rownumber = 1


--FI02

left join (
	select CA.StudyId, Time as Fio2_Time, CAST(Value/100 as decimal(18,2)) as fio2_0,

	row_number() over(partition by CA.StudyId order by Time desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID


	join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_0,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	where ParameterID = 277
	and Time <= DATEADD(hh,12,ROSC)
	) as o2sat_0 on CA.StudyId = o2sat_0.StudyId
	and O2sat_RN = 1

	and ParameterID = 3835
	and Time <= DATEADD(hh,12,ROSC)
	and time <= Sat_Time
	) as fio2_0 on CA.StudyId = fio2_0.StudyId
	and fio2_0.RN = 1





--Acutal Query Starts Here

select CA.StudyId, CA.PatientId, CA.MRN, Patients.SocialSecurity as FN,

DIAGNOSIS, Adm_dt, disch_dt,

DATEDIFF(yy,dob,ADMISSIONS.adm_dt) as Age, Gender, race_full, weight, ADMISSIONS.height, disch_disp_full,

CA.Addmissiondate, CA.dischargedate, DateOfArrest, TimeOfArrest, CA.ROSC,
Location, AdmitDate, Rhythm, Cooling, CPC,

plt_0, plt_sofa_0, bili_0, bili_sofa_0, cr_0, cr_sofa_0, GCS_0, gcs_sofa_0, MAP_0, DopamineRate_0,

DobutamineRate_0, EpinephrineRate_0, NorepinephrineRate_0, cv_sofa_0, fio2_0, o2sat_0, resp_sofa_0,

(plt_sofa_0 + bili_sofa_0 + cr_sofa_0 + gcs_sofa_0 + cv_sofa_0 + resp_sofa_0) as SOFA_SCORE_0,

PhenylRate_0, VasopressinRate_0

from CA

join Patients on CA.PatientId = Patients.PatientID

left join ADMISSIONS on Patients.SocialSecurity = ADMISSIONS.fiscal_num

join (


select CA.StudyId, CA.ROSC, DischargeDate,

plt_0,

CASE 
WHEN plt_0 < 20 then 4
WHEN plt_0 < 50 then 3
WHEN plt_0 < 100 then 2
WHEN plt_0 < 150 then 1
WHEN plt_0 >= 150 then 0
End as plt_sofa_0,

bili_0,

CASE
WHEN bili_0 > 12.0 then 4
WHEN bili_0 >= 6.0 then 3
WHEN bili_0 >= 2.0 then 2
WHEN bili_0 >= 1.2 then 1
WHEN bili_0 < 1.2 then 0
END as bili_sofa_0,

cr_0,

CASE
WHEN cr_0 > 5.0 then 4
WHEN cr_0 >= 3.5 then 3
WHEN cr_0 >= 2.0 then 2
WHEN cr_0 >= 1.2 then 1
WHEN cr_0 < 1.2 then 1
END as cr_sofa_0,

GCS_0, GCS_Time,

CASE 
WHEN GCS_0 < 6 then 4
WHEN GCS_0 <= 9 then 3
WHEN GCS_0 <= 12 then 2
WHEN GCS_0 <= 14 then 1
WHEN GCS_0 > 14 then 0
END as gcs_sofa_0,

DopamineRate_0, DobutamineRate_0, EpinephrineRate_0, NorepinephrineRate_0,

MAP_0,

CASE
WHEN DopamineRate_0 > 15 or EpinephrineRate_0 > 0.1 or NorepinephrineRate_0 > 0.1 then 4
WHEN DopamineRate_0 > 5 or EpinephrineRate_0 <= 0.1 or NorepinephrineRate_0 <= 0.1 then 3
WHEN DopamineRate_0 <= 5 or DobutamineRate_0 is not null then 2
WHEN MAP_0 < 70 then 1
WHEN MAP_0 >= 70 then 0
END as cv_sofa_0,

o2sat_0, FlowFIO2, fio2_0,

CASE
WHEN fio2_0 = 0 then null
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is null and o2sat_0/fio2_0 < 151 then 4
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is null and o2sat_0/fio2_0 <= 235 then 3
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is null and o2sat_0/fio2_0 <= 315 then 2
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is null and o2sat_0/fio2_0 <= 399 then 1
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is null and o2sat_0/fio2_0 > 399 then 0


WHEN o2sat_0 is not null and fio2_0 is null and FlowFIO2 is not null and o2sat_0/FlowFIO2 < 151 then 4
WHEN o2sat_0 is not null and fio2_0 is null and FlowFIO2 is not null and o2sat_0/FlowFIO2 <= 235 then 3
WHEN o2sat_0 is not null and fio2_0 is null and FlowFIO2 is not null and o2sat_0/FlowFIO2 <= 315 then 2
WHEN o2sat_0 is not null and fio2_0 is null and FlowFIO2 is not null and o2sat_0/FlowFIO2 <= 399 then 1
WHEN o2sat_0 is not null and fio2_0 is null and FlowFIO2 is not null and o2sat_0/FlowFIO2 > 399 then 0




WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_0/fio2_0 < 151 then 4
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_0/fio2_0 <= 235 then 3
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_0/fio2_0 <= 315 then 2
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_0/fio2_0 <= 399 then 1
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_0/fio2_0 > 399 then 0

WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_0/FlowFIO2 < 151 then 4
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_0/FlowFIO2 <= 235 then 3
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_0/FlowFIO2 <= 315 then 2
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_0/FlowFIO2 <= 399 then 1
WHEN o2sat_0 is not null and fio2_0 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_0/FlowFIO2 > 399 then 0


END as resp_sofa_0, Fio2_Time, Flow_Time, PhenylRate_0, VasopressinRate_0


from CA

--baseline platelet sofa

left join (
	select CA.StudyId, Time, CAST(Value as int) as plt_0,

	row_number() over(partition by CA.StudyId order by Value) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 7457
	and Time <= DATEADD(hh,12,ROSC)
	and CAST(Value as int) <= 5000
	) as plt_0 on CA.StudyId = plt_0.StudyId
	and plt_0.RN = 1


--Baseline bilirubin sofa

left join (
	select CA.StudyId, Time, CAST(Value as decimal(18,2)) as bili_0,

	row_number() over(partition by CA.StudyId order by Value desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 5690
	and Time <= DATEADD(hh,12,ROSC)
	and CAST(Value as decimal(18,2)) <= 1000
	) as bili_0 on CA.StudyId = bili_0.StudyId
	and bili_0.RN = 1


--Baseline creatinine sofa

left join (
	select CA.StudyId, Time, CAST(Value as decimal(18,2)) as cr_0,

	row_number() over(partition by CA.StudyId order by Value desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 615
	and Time <= DATEADD(hh,12,ROSC)
	and CAST(Value as decimal(18,2)) <= 1000
	) as cr_0 on CA.StudyId = cr_0.StudyId
	and cr_0.RN = 1


--gcs sofa score

left join (

Select CA.StudyId, Time as GCS_Time, GCS as GCS_0,

row_number() over(partition by CA.StudyId order by GCS) as RN

from CA
join GCS on CA.PatientId = GCS.PatientID

where Time <= DATEADD(hh,12,ROSC)

) GCS_0 on CA.StudyId = GCS_0.StudyId
and GCS_0.RN = 1

--Dopamine Rate

left join (
	select CA.StudyId, OriginalRate as DopamineRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1662
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as dopamine_0 on CA.StudyId = dopamine_0.StudyId
	and dopamine_0.RN = 1

--Dobutamine Rate

left join (
	select CA.StudyId, OriginalRate as DobutamineRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1653
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as dobutamine_0 on CA.StudyId = dobutamine_0.StudyId
	and dobutamine_0.RN = 1


--Epinephrine Rate

left join (
	select CA.StudyId, OriginalRate as EpinephrineRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1289
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as epi_0 on CA.StudyId = epi_0.StudyId
	and epi_0.RN = 1

--Norepinephrine Rate

left join (
	select CA.StudyId, OriginalRate as NorepinephrineRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1906
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as norepi_0 on CA.StudyId = norepi_0.StudyId
	and norepi_0.RN = 1


--Phenyl Rate

left join (
	select CA.StudyId, OriginalRate as PhenylRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1749
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as phenyl_0 on CA.StudyId = phenyl_0.StudyId
	and phenyl_0.RN = 1

--Phenyl Rate

left join (
	select CA.StudyId, OriginalRate as VasopressinRate_0,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 2315
	and StartTime <= DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as vasopressin_0 on CA.StudyId = vasopressin_0.StudyId
	and vasopressin_0.RN = 1

left join (

select CA.StudyId,  SBP_Time, (DBP_0*2 + SBP_0)/3 as MAP_0,

--DBP_0, DBP_Time, ROSC, SBP_0,


row_number() over(partition by CA.StudyId order by ((DBP_0*2 + SBP_0)/3)) as RowNumber

from CA
join (
	select CA.StudyId, Time as SBP_Time, Value/133.3222 as SBP_0
		
	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID in ( '50', '179', '5309')
	and Time <= DATEADD(hh,12,ROSC)
	) as SBP_0 on CA.StudyId = SBP_0.StudyId
join (
	select CA.StudyId, Time as DBP_Time, Value/133.3222 as DBP_0

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID in ( '51', '180', '5310')
	and Time <= DATEADD(hh,12,ROSC)
	and Value > 0 
	) as DBP_0 on CA.StudyId = DBP_0.StudyId
	and SBP_0.SBP_Time = DBP_0.DBP_Time
	and SBP_0 > DBP_0

) MAP_0 on CA.StudyId = MAP_0.StudyId
and MAP_0.RowNumber = 1

--O2SAT

left join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_0,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 277
	and Time <= DATEADD(hh,12,ROSC)
	) as o2sat_0 on CA.StudyId = o2sat_0.StudyId
	and o2sat_0.O2sat_RN = 1


LEFT JOIN #Temp0HourO2sat Oxygen on CA.StudyId = Oxygen.StudyId



) SOFASCORE on CA.StudyId = SOFASCORE.StudyId


--where CA.PatientID = 64445

order by CAST(CA.StudyId as int)