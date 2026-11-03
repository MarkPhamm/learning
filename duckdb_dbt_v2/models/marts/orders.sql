with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

joined as (

    select
        orders.order_id,
        orders.customer_id,
        customers.customer_name,
        customers.country,
        orders.product_id,
        products.product_name,
        products.category,
        orders.ordered_at,
        orders.status,
        orders.amount,
        orders.status = 'completed' as is_completed
    from orders
    left join customers
        on orders.customer_id = customers.customer_id
    left join products
        on orders.product_id = products.product_id

)

select * from joined
