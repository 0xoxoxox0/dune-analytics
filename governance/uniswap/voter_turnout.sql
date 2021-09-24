SELECT p.*,
    p.total_for_votes / 1000000000 as for_voted,
    p.total_against_votes / 1000000000 as against_voted,
    (1000000000 - (p.total_for_votes + p.total_against_votes)) / 1000000000 as unvoted
FROM (
    SELECT
        "proposalId",
        TRUNC(sum(
            CASE support
                WHEN true then votes
                ELSE 0
            END
        ) / 10^18) as total_for_votes,
        TRUNC(sum(
            CASE support
                WHEN false then votes
                ELSE 0
            END
        ) / 10^18) as total_against_votes
    FROM uniswap_v2."GovernorAlpha_evt_VoteCast"
    group by "proposalId"
)  as p
order by "proposalId" desc;
