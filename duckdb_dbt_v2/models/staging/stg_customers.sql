with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        country,
        first_name || ' ' || last_name as customer_name
    from source

)

select * from renamed
