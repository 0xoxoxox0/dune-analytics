SELECT p.*,
    p.total_for_votes / 16000000 as for_voted,
    p.total_against_votes / 16000000 as against_voted,
    (16000000 - (p.total_for_votes + p.total_against_votes)) / 16000000 as unvoted
FROM (
    SELECT
        "id" as "proposalId",
        TRUNC(sum(
            CASE support
                WHEN true then "votingPower"
                ELSE 0
            END
        ) / 10^18) as total_for_votes,
        TRUNC(sum(
            CASE support
                WHEN false then "votingPower"
                ELSE 0
            END
        ) / 10^18) as total_against_votes
    FROM aave."AaveGovernanceV2_evt_VoteEmitted"
    group by "id"
) as p
order by "proposalId" desc;
