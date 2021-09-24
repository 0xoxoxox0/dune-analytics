WITH governor_alpha as (
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
        ) / 10^18) as total_against_votes,
        0 as total_abstain_votes
    FROM compound_v2."GovernorAlpha_evt_VoteCast"
    group by "proposalId"
), governor_bravo as (
    SELECT
        "proposalId",
        TRUNC(sum(
            CASE support
                WHEN 1 then votes
                ELSE 0
            END
        ) / 10^18) as total_for_votes,
        TRUNC(sum(
            CASE support
                WHEN 0 then votes
                ELSE 0
            END
        ) / 10^18) as total_against_votes,
        TRUNC(sum(
            CASE support
                WHEN 2 then votes
                ELSE 0
            END
        ) / 10^18) as total_abstain_votes
    FROM compound_v2."GovernorBravoDelegate_evt_VoteCast"
    group by "proposalId"
), governor_union as (
    SELECT * from governor_alpha
    UNION ALL
    SELECT * from governor_bravo
)
SELECT p.*,
    p.total_for_votes / 10000000 as for_voted,
    p.total_against_votes / 10000000 as against_voted,
    p.total_abstain_votes / 10000000 as abstain_voted,
    (10000000 - (p.total_for_votes + p.total_against_votes + p.total_abstain_votes)) / 10000000 as unvoted
FROM governor_union p
order by "proposalId" desc;
