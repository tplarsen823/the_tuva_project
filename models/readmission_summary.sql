
-- Here calculate days to readmission for encounters
-- that had a readmission and create readmission flags


{{ config(materialized='table') }}



-- We create the encounter_sequence integer count
-- which keeps track of what number of encounter each
-- encounter is for a given patient
with encounter_sequence as (
select
    *,
    row_number() over(
        partition by patient_id order by admit_date, discharge_date
    ) as encounter_sequence
from {{ ref('encounter_augmented') }}
where disqualified_encounter_flag = 0
),


readmission_calc as (
select
    aa.encounter_id,
    aa.patient_id,
    aa.admit_date,
    aa.discharge_date,
    aa.discharge_status_code,
    aa.facility,
    aa.ms_drg,
    aa.length_of_stay,
    aa.index_admission_flag,
    aa.planned_flag,
    aa.specialty_cohort,
    aa.died_flag,
    aa.diagnosis_ccs,
    case
        when bb.encounter_id is not null then 1
	else 0
    end as had_readmission_flag,
    bb.admit_date - aa.discharge_date as days_to_readmit,
    case
        when (bb.admit_date - aa.discharge_date) <= 30  then 1
	else 0
    end as readmit_30_flag,
    case
        when
	    ((bb.admit_date - aa.discharge_date) <= 30)
	    and
	    (bb.planned_flag = 0) then 1
	else 0
    end as unplanned_readmit_30_flag,
    bb.encounter_id as readmission_encounter_id,
    bb.admit_date as readmission_admit_date,
    bb.discharge_date as readmission_discharge_date,
    bb.discharge_status_code as readmission_discharge_status_code,
    bb.facility as readmission_facility,
    bb.ms_drg as readmission_ms_drg,
    bb.length_of_stay as readmission_length_of_stay,
    bb.index_admission_flag as readmission_index_admission_flag,
    bb.planned_flag as readmission_planned_flag,
    bb.specialty_cohort as readmission_specialty_cohort,
    bb.died_flag as readmission_died_flag,
    bb.diagnosis_ccs as readmission_diagnosis_ccs


from
    encounter_sequence aa
    left join encounter_sequence bb
    on aa.patient_id = bb.patient_id
    and aa.encounter_sequence + 1 = bb.encounter_sequence
)



select *
from readmission_calc