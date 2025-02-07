{{ config(
     enabled = var('data_profiling_enabled',var('tuva_marts_enabled',True))
   )
}}

{% set professional_missing_column_list = [
      'claim_id'
    , 'claim_line_number'
    , 'patient_id'
    , 'member_id'
    , 'claim_start_date'
    , 'claim_end_date'
    , 'place_of_service_code'
    , 'hcpcs_code'
    , 'rendering_npi'
    , 'billing_npi'
    , 'paid_date'
    , 'paid_amount'
    , 'diagnosis_code_type'
    , 'diagnosis_code_1'
    , 'data_source'
] -%}

with professional_missing as(

 {{ medical_claim_missing_column_check(builtins.ref('medical_claim'), professional_missing_column_list, 'professional') }}

)

select
      'medical_claim' as source_table
    , 'professional' as claim_type
    , 'claim_id' as grain
    ,  claim_id    
    , 'missing_values' as test_category
    , column_checked||' missing' as test_name
    , '{{ var('last_update')}}' as last_update
from professional_missing
group by
    claim_id
    , column_checked||' missing'