with source as (

    select * from {{ ref('raw_products') }}

),

renamed as (

    select
        product_id,
        product_name,
        category
    from source

)

select * from renamed
