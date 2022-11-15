If(OBJECT_ID('tempdb..#Temp0HourO2sat') Is Not Null) Begin Drop Table #Temp0HourO2sat End



CREATE TABLE #Temp0HourO2sat (StudyId int, FlowFIO2 decimal(18,2), fio2_24 decimal(18,2), Flow_Time DateTime, Fio2_Time DateTime)

INSERT INTO #Temp0HourO2sat (StudyId, FlowFIO2, fio2_24, Flow_Time, Fio2_Time)

select CA.StudyId, (21 + o2flow_24*3)/100 as FlowFIO2, fio2_24, Flow_Time, Fio2_Time

from CA

--O2 Flow

left join (
	select CA.StudyId, Time as Flow_Time, CAST(Value/1000 as decimal(18,2)) as o2flow_24,

	row_number() over(partition by CA.StudyId order by Time desc) as O2Flow_Rownumber

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID

	--Added O2 Sat query to use the SAT_Time before the RN limiter

	join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_24,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	where ParameterID = 277
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	) as o2sat_24 on CA.StudyId = o2sat_24.StudyId
	and O2sat_RN = 1

	and ParameterID in ( '3834', '7287', '7582')
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and Time <= Sat_Time
	) as o2flow_24 on CA.StudyId = o2flow_24.StudyId
	and O2Flow_Rownumber = 1


--FI02

left join (
	select CA.StudyId, Time as Fio2_Time, CAST(Value/100 as decimal(18,2)) as fio2_24,

	row_number() over(partition by CA.StudyId order by Time desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID


	join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_24,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	where ParameterID = 277
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	) as o2sat_24 on CA.StudyId = o2sat_24.StudyId
	and O2sat_RN = 1

	and ParameterID = 3835
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and time <= Sat_Time
	) as fio2_24 on CA.StudyId = fio2_24.StudyId
	and fio2_24.RN = 1





--Acutal Query Starts Here

select CA.StudyId, 

--CA.PatientId, CA.MRN, Patients.SocialSecurity as FN,

--DIAGNOSIS,

--DATEDIFF(yy,dob,ADMISSIONS.adm_dt) as Age, Gender, race_full, weight, ADMISSIONS.height, disch_disp_full,

--CA.Addmissiondate, CA.dischargedate, DateOfArrest, TimeOfArrest, CA.ROSC,
--Location, AdmitDate, Rhythm, Cooling, CPC,

plt_24, plt_sofa_24, bili_24, bili_sofa_24, cr_24, cr_sofa_24, GCS_24, gcs_sofa_24, MAP_24, DopamineRate_24,

DobutamineRate_24, EpinephrineRate_24, NorepinephrineRate_24, cv_sofa_24, fio2_24, o2sat_24, resp_sofa_24,

(plt_sofa_24 + bili_sofa_24 + cr_sofa_24 + gcs_sofa_24 + cv_sofa_24 + resp_sofa_24) as SOFA_SCORE_24,

PhenylRate_24, VasopressinRate_24

from CA

join Patients on CA.PatientId = Patients.PatientID

left join ADMISSIONS on Patients.SocialSecurity = ADMISSIONS.fiscal_num

join (


select CA.StudyId, CA.ROSC, DischargeDate,

plt_24,

CASE 
WHEN plt_24 < 20 then 4
WHEN plt_24 < 50 then 3
WHEN plt_24 < 100 then 2
WHEN plt_24 < 150 then 1
WHEN plt_24 >= 150 then 0
End as plt_sofa_24,

bili_24,

CASE
WHEN bili_24 > 12.0 then 4
WHEN bili_24 >= 6.0 then 3
WHEN bili_24 >= 2.0 then 2
WHEN bili_24 >= 1.2 then 1
WHEN bili_24 < 1.2 then 0
END as bili_sofa_24,

cr_24,

CASE
WHEN cr_24 > 5.0 then 4
WHEN cr_24 >= 3.5 then 3
WHEN cr_24 >= 2.0 then 2
WHEN cr_24 >= 1.2 then 1
WHEN cr_24 < 1.2 then 1
END as cr_sofa_24,

GCS_24, GCS_Time,

CASE 
WHEN GCS_24 < 6 then 4
WHEN GCS_24 <= 9 then 3
WHEN GCS_24 <= 12 then 2
WHEN GCS_24 <= 14 then 1
WHEN GCS_24 > 14 then 0
END as gcs_sofa_24,

DopamineRate_24, DobutamineRate_24, EpinephrineRate_24, NorepinephrineRate_24,

MAP_24,

CASE
WHEN DopamineRate_24 > 15 or EpinephrineRate_24 > 0.1 or NorepinephrineRate_24 > 0.1 then 4
WHEN DopamineRate_24 > 5 or EpinephrineRate_24 <= 0.1 or NorepinephrineRate_24 <= 0.1 then 3
WHEN DopamineRate_24 <= 5 or DobutamineRate_24 is not null then 2
WHEN MAP_24 < 70 then 1
WHEN MAP_24 >= 70 then 0
END as cv_sofa_24,

o2sat_24, FlowFIO2, fio2_24,

CASE
WHEN fio2_24 = 0 then null
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is null and o2sat_24/fio2_24 < 151 then 4
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is null and o2sat_24/fio2_24 <= 235 then 3
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is null and o2sat_24/fio2_24 <= 315 then 2
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is null and o2sat_24/fio2_24 <= 399 then 1
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is null and o2sat_24/fio2_24 > 399 then 0


WHEN o2sat_24 is not null and fio2_24 is null and FlowFIO2 is not null and o2sat_24/FlowFIO2 < 151 then 4
WHEN o2sat_24 is not null and fio2_24 is null and FlowFIO2 is not null and o2sat_24/FlowFIO2 <= 235 then 3
WHEN o2sat_24 is not null and fio2_24 is null and FlowFIO2 is not null and o2sat_24/FlowFIO2 <= 315 then 2
WHEN o2sat_24 is not null and fio2_24 is null and FlowFIO2 is not null and o2sat_24/FlowFIO2 <= 399 then 1
WHEN o2sat_24 is not null and fio2_24 is null and FlowFIO2 is not null and o2sat_24/FlowFIO2 > 399 then 0




WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_24/fio2_24 < 151 then 4
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_24/fio2_24 <= 235 then 3
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_24/fio2_24 <= 315 then 2
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_24/fio2_24 <= 399 then 1
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time > Flow_Time and o2sat_24/fio2_24 > 399 then 0

WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_24/FlowFIO2 < 151 then 4
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_24/FlowFIO2 <= 235 then 3
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_24/FlowFIO2 <= 315 then 2
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_24/FlowFIO2 <= 399 then 1
WHEN o2sat_24 is not null and fio2_24 is not null and FlowFIO2 is not null and Fio2_Time < Flow_Time and o2sat_24/FlowFIO2 > 399 then 0


END as resp_sofa_24, Fio2_Time, Flow_Time, PhenylRate_24, VasopressinRate_24


from CA

--baseline platelet sofa

left join (
	select CA.StudyId, Time, CAST(Value as int) as plt_24,

	row_number() over(partition by CA.StudyId order by Value) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 7457
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and CAST(Value as int) <= 5000
	) as plt_24 on CA.StudyId = plt_24.StudyId
	and plt_24.RN = 1


--Baseline bilirubin sofa

left join (
	select CA.StudyId, Time, CAST(Value as decimal(18,2)) as bili_24,

	row_number() over(partition by CA.StudyId order by Value desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 5690
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and CAST(Value as decimal(18,2)) <= 1000
	) as bili_24 on CA.StudyId = bili_24.StudyId
	and bili_24.RN = 1


--Baseline creatinine sofa

left join (
	select CA.StudyId, Time, CAST(Value as decimal(18,2)) as cr_24,

	row_number() over(partition by CA.StudyId order by Value desc) as RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 615
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and CAST(Value as decimal(18,2)) <= 1000
	) as cr_24 on CA.StudyId = cr_24.StudyId
	and cr_24.RN = 1


--gcs sofa score

left join (

Select CA.StudyId, Time as GCS_Time, GCS as GCS_24,

row_number() over(partition by CA.StudyId order by GCS) as RN

from CA
join GCS on CA.PatientId = GCS.PatientID

	where Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)

) GCS_24 on CA.StudyId = GCS_24.StudyId
and GCS_24.RN = 1

--Dopamine Rate

left join (
	select CA.StudyId, OriginalRate as DopamineRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1662
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as dopamine_24 on CA.StudyId = dopamine_24.StudyId
	and dopamine_24.RN = 1

--Dobutamine Rate

left join (
	select CA.StudyId, OriginalRate as DobutamineRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1653
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as dobutamine_24 on CA.StudyId = dobutamine_24.StudyId
	and dobutamine_24.RN = 1


--Epinephrine Rate

left join (
	select CA.StudyId, OriginalRate as EpinephrineRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1289
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as epi_24 on CA.StudyId = epi_24.StudyId
	and epi_24.RN = 1

--Norepinephrine Rate

left join (
	select CA.StudyId, OriginalRate as NorepinephrineRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1906
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as norepi_24 on CA.StudyId = norepi_24.StudyId
	and norepi_24.RN = 1


--Phenyl Rate

left join (
	select CA.StudyId, OriginalRate as PhenylRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 1749
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as phenyl_24 on CA.StudyId = phenyl_24.StudyId
	and phenyl_24.RN = 1

--Phenyl Rate

left join (
	select CA.StudyId, OriginalRate as VasopressinRate_24,

	row_number() over(partition by CA.StudyId order by OriginalRate desc) as RN

	from CA
	Join RangeSignals_CA on CA.PatientID = RangeSignals_CA.PatientID
	and ParameterID = 2315
	and StartTime <= DATEADD(hh,36,ROSC)
	and StartTime > DATEADD(hh,12,ROSC)
	and RangeSignals_CA.status != 4
	and DripUnitID is not null
	) as vasopressin_24 on CA.StudyId = vasopressin_24.StudyId
	and vasopressin_24.RN = 1

left join (

select CA.StudyId,  SBP_Time, (DBP_24*2 + SBP_24)/3 as MAP_24,

--DBP_24, DBP_Time, ROSC, SBP_24,


row_number() over(partition by CA.StudyId order by ((DBP_24*2 + SBP_24)/3)) as RowNumber

from CA
join (
	select CA.StudyId, Time as SBP_Time, Value/133.3222 as SBP_24
		
	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID in ( '50', '179', '5309')
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	) as SBP_24 on CA.StudyId = SBP_24.StudyId
join (
	select CA.StudyId, Time as DBP_Time, Value/133.3222 as DBP_24

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID in ( '51', '180', '5310')
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	and Value > 0 
	) as DBP_24 on CA.StudyId = DBP_24.StudyId
	and SBP_24.SBP_Time = DBP_24.DBP_Time
	and SBP_24 > DBP_24

) MAP_24 on CA.StudyId = MAP_24.StudyId
and MAP_24.RowNumber = 1

--O2SAT

left join (
	select CA.StudyId, Time as Sat_Time, CAST(Value as int) as o2sat_24,

	row_number() over(partition by CA.StudyId order by Value) as O2sat_RN

	from CA
	Join Signals_CA on CA.PatientID = Signals_CA.PatientID
	and ParameterID = 277
	and Time <= DATEADD(hh,36,ROSC)
	and Time > DATEADD(hh,12,ROSC)
	) as o2sat_24 on CA.StudyId = o2sat_24.StudyId
	and o2sat_24.O2sat_RN = 1


LEFT JOIN #Temp0HourO2sat Oxygen on CA.StudyId = Oxygen.StudyId



) SOFASCORE on CA.StudyId = SOFASCORE.StudyId


--where CA.PatientID = 64445

order by CAST(CA.StudyId as int)