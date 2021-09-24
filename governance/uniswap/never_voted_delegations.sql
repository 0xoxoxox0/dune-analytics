with group_sort as (
select "delegate", "newBalance" as voting_power, ROW_NUMBER() OVER (partition by "delegate" order by "evt_block_number" desc, "evt_index" desc) as rn
            from uniswap."UNI_evt_DelegateVotesChanged"
)
select res.delegate as address, res.voting_power / 1e18 as voting_power, (to_amt - coalesce(from_amt, 0)) / 1e18 as current_balance
    from group_sort res
    left join (select "to", sum(amount) as to_amt from uniswap."UNI_evt_Transfer" group by "to") t on t."to" = res.delegate
    left join (select "from", sum(amount) as from_amt from uniswap."UNI_evt_Transfer" group by "from") f on f."from" = t."to"
    where (to_amt - coalesce(from_amt, 0)) / 1e18 > 0
    and t.to not in (SELECT "voter" FROM uniswap_v2."GovernorAlpha_evt_VoteCast")
    and rn = 1
    order by res.voting_power desc;
