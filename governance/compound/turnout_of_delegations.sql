with delegation_info_with_rn as (
    select "delegate" as address, "newBalance" / 1e18 as delegated_amount, ROW_NUMBER() OVER (partition by "delegate" order by "evt_block_number" desc, "evt_index" desc) as rn
        from compound_v2."Comp_evt_DelegateVotesChanged"
), delegation_info as (
    select address, delegated_amount from delegation_info_with_rn
        where rn = 1
), total_delegations as (
    select sum(res.delegated_amount) as amount, sum(1.0) as num from delegation_info res
), unvoted_delegations as (
    select sum(res.delegated_amount) as amount, sum(1.0) as num from delegation_info res
    where res.address not in (SELECT "voter" FROM compound_v2."GovernorAlpha_evt_VoteCast" UNION SELECT "voter" FROM compound_v2."GovernorBravoDelegate_evt_VoteCast")
)
select
    total.amount as total_delegation_amount,
    total.num as total_delegatee_count,
    unvoted.amount as unvoted_delegation_amount,
    unvoted.num as unvoted_delegatee_count,
    to_char(unvoted.amount / total.amount * 100, '999D99%') as unvoted_delegation_percent,
    to_char(unvoted.num / total.num * 100, '999D99%') as unvoted_delegatee_percent
from total_delegations total, unvoted_delegations unvoted;
