with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        product_id,
        cast(ordered_at as date) as ordered_at,
        status,
        cast(amount as decimal(10, 2)) as amount
    from source

)

select * from renamed
