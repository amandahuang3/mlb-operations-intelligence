with batting as (
    select * from {{ ref('stg_batting') }}
),

people as (
    select 
        player_id,
        first_name,
        last_name,
        birth_country,
        bats_hand,
        mlb_debut_date
    from {{ ref('stg_people') }}
),

-- aggregate stints: sum counting stats per player per season
batting_aggregated as (
    select
        player_id,
        year_id,
        -- take the last team when multiple stints (most recent team)
        max(team_id)                                as team_id,
        max(league_id)                              as league_id,
        sum(games)                                  as games,
        sum(at_bats)                                as at_bats,
        sum(runs)                                   as runs,
        sum(hits)                                   as hits,
        sum(doubles)                                as doubles,
        sum(triples)                                as triples,
        sum(home_runs)                              as home_runs,
        sum(rbi)                                    as rbi,
        sum(walks)                                  as walks,
        sum(strikeouts)                             as strikeouts,
        sum(stolen_bases)                           as stolen_bases,
        sum(hit_by_pitch)                           as hit_by_pitch,
        sum(sacrifice_flies)                        as sacrifice_flies
    from batting
    group by player_id, year_id
),

-- calculate OBP, SLG, OPS
with_metrics as (
    select
        player_id,
        year_id,
        team_id,
        league_id,
        games,
        at_bats,
        runs,
        hits,
        doubles,
        triples,
        home_runs,
        rbi,
        walks,
        strikeouts,
        stolen_bases,

        -- OBP = (H + BB + HBP) / (AB + BB + HBP + SF)
        round(
            safe_divide(
                (hits + walks + coalesce(hit_by_pitch, 0)),
                (at_bats + walks + coalesce(hit_by_pitch, 0) + coalesce(sacrifice_flies, 0))
            ), 3
        )                                           as obp,

        -- SLG = (1B + 2*2B + 3*3B + 4*HR) / AB
        round(
            safe_divide(
                (hits - doubles - triples - home_runs)
                + (2 * doubles)
                + (3 * triples)
                + (4 * home_runs),
                at_bats
            ), 3
        )                                           as slg

    from batting_aggregated
),

final as (
    select
        b.player_id,
        b.year_id,
        b.team_id,
        b.league_id,
        p.first_name,
        p.last_name,
        p.birth_country,
        p.bats_hand,
        b.games,
        b.at_bats,
        b.runs,
        b.hits,
        b.doubles,
        b.triples,
        b.home_runs,
        b.rbi,
        b.walks,
        b.strikeouts,
        b.stolen_bases,
        b.obp,
        b.slg,

        -- OPS = OBP + SLG (your batter value proxy)
        round(
            coalesce(b.obp, 0) + coalesce(b.slg, 0), 3
        )                                           as ops,

        -- quality tier for filtering in Tableau
        case
            when at_bats < 100 then 'Insufficient AB'
            when (coalesce(b.obp, 0) + coalesce(b.slg, 0)) >= 0.900 then 'Elite'
            when (coalesce(b.obp, 0) + coalesce(b.slg, 0)) >= 0.800 then 'Above Average'
            when (coalesce(b.obp, 0) + coalesce(b.slg, 0)) >= 0.700 then 'Average'
            else 'Below Average'
        end                                         as ops_tier

    from with_metrics b
    left join people p
        on b.player_id = p.player_id
)

select * from final