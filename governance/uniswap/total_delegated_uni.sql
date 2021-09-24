with group_sort as (
select "delegate", "newBalance" as voting_power, ROW_NUMBER() OVER (partition by "delegate" order by "evt_block_number" desc, "evt_index" desc) as rn
            from uniswap."UNI_evt_DelegateVotesChanged"
)
select sum(res.voting_power)/ 1e18 as voting_power
    from group_sort res
    where rn = 1;
