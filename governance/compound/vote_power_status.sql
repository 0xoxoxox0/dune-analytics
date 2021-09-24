with balance_sort as (
    select "to" as address, (to_amt - coalesce(from_amt, 0)) / 1e18 as current_balance
        from (select "to", sum(amount) as to_amt from compound_v2."Comp_evt_Transfer" group by "to") t
        left join (select "from", sum(amount) as from_amt from compound_v2."Comp_evt_Transfer" group by "from") f on f."from" = t."to"
        where (to_amt - coalesce(from_amt, 0)) / 1e18 > 0
        order by current_balance desc
), delegation_sort_with_rn as (
    select "delegate" as address, "newBalance" / 1e18 as delegated_amount, ROW_NUMBER() OVER (partition by "delegate" order by "evt_block_number" desc, "evt_index" desc) as rn
        from compound_v2."Comp_evt_DelegateVotesChanged"
), delegation_sort as (
    select * from delegation_sort_with_rn
        where rn = 1
)
select
    coalesce(b.address, d.address) as address,
    coalesce(b.current_balance, 0) as current_balance,
    coalesce(d.delegated_amount, 0) as delegated_amount,
    case coalesce(b.address, d.address) in (select DISTINCT delegator from compound_v2."Comp_evt_DelegateChanged")
        when true then coalesce(d.delegated_amount, 0)
        else coalesce(b.current_balance, 0) + coalesce(d.delegated_amount, 0)
    end as substantial_voting_power,
    coalesce(b.address, d.address) not in (SELECT "voter" FROM compound_v2."GovernorAlpha_evt_VoteCast" UNION SELECT "voter" FROM compound_v2."GovernorBravoDelegate_evt_VoteCast") as never_voted
from balance_sort b
full outer join delegation_sort d on d.address = b.address
order by substantial_voting_power desc;
