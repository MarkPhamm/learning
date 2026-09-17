with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

order_stats as (

    select
        customer_id,
        count(*) as order_count,
        sum(amount) as lifetime_revenue,
        min(ordered_at) as first_ordered_at,
        max(ordered_at) as last_ordered_at
    from orders
    where status = 'completed'
    group by customer_id

),

joined as (

    select
        customers.customer_id,
        customers.customer_name,
        customers.country,
        order_stats.first_ordered_at,
        order_stats.last_ordered_at,
        coalesce(order_stats.order_count, 0) as order_count,
        coalesce(order_stats.lifetime_revenue, 0) as lifetime_revenue
    from customers
    left join order_stats
        on customers.customer_id = order_stats.customer_id

)

select * from joined
