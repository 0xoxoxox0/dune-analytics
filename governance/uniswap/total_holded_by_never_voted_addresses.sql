with balance_sort as (
    select "to" as address, (to_amt - coalesce(from_amt, 0)) / 1e18 as current_balance
        from (select "to", sum(amount) as to_amt from uniswap."UNI_evt_Transfer" group by "to") t
        left join (select "from", sum(amount) as from_amt from uniswap."UNI_evt_Transfer" group by "from") f on f."from" = t."to"
        where (to_amt - coalesce(from_amt, 0)) / 1e18 > 0
        order by current_balance desc
), delegation_sort_with_rn as (
    select "delegate" as address, "newBalance" / 1e18 as delegated_amount, ROW_NUMBER() OVER (partition by "delegate" order by "evt_block_number" desc, "evt_index" desc) as rn
        from uniswap."UNI_evt_DelegateVotesChanged"
), delegation_sort as (
    select * from delegation_sort_with_rn
        where rn = 1
)
select
    sum(
        case coalesce(b.address, d.address) in (select DISTINCT delegator from uniswap."UNI_evt_DelegateChanged")
            when true then coalesce(d.delegated_amount, 0)
            else coalesce(b.current_balance, 0) + coalesce(d.delegated_amount, 0)
        end
    )
from balance_sort b
full outer join delegation_sort d on d.address = b.address
where coalesce(b.address, d.address) not in (SELECT "voter" FROM uniswap_v2."GovernorAlpha_evt_VoteCast");
