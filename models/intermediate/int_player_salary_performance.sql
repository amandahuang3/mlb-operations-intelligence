with salaries as (
    select * from {{ ref('stg_salaries') }}
),

batting as (
    select
        player_id,
        year_id,
        team_id,
        first_name,
        last_name,
        birth_country,
        games,
        at_bats,
        hits,
        home_runs,
        rbi,
        walks,
        strikeouts,
        obp,
        slg,
        ops,
        ops_tier
    from {{ ref('int_player_batting_enriched') }}
    where at_bats >= 100  -- minimum threshold for meaningful stats
),

pitching as (
    select
        player_id,
        year_id,
        team_id,
        first_name,
        last_name,
        birth_country,
        games,
        games_started,
        saves,
        innings_pitched,
        era_calculated,
        k_per_9,
        bb_per_9,
        whip,
        pitching_efficiency_proxy,
        pitcher_role,
        era_tier
    from {{ ref('int_player_pitching_enriched') }}
    where innings_pitched >= 30  -- minimum threshold for meaningful stats
),

-- join salaries to batters
batter_salaries as (
    select
        s.player_id,
        s.year_id,
        s.team_id,
        s.salary,
        b.first_name,
        b.last_name,
        b.birth_country,
        b.games,
        b.at_bats,
        b.hits,
        b.home_runs,
        b.rbi,
        b.obp,
        b.slg,
        b.ops,
        b.ops_tier,
        'Batter'                                    as player_type,
        cast(null as float64)                       as era_calculated,
        cast(null as float64)                       as innings_pitched,
        cast(null as float64)                       as whip,
        cast(null as float64)                       as pitching_efficiency_proxy,
        cast(null as string)                        as era_tier,
        -- efficiency: OPS per $1M salary
        round(
            safe_divide(b.ops, s.salary / 1000000), 4
        )                                           as ops_per_million,
        cast(null as float64)                       as era_per_million

    from salaries s
    inner join batting b
        on s.player_id = b.player_id
        and s.year_id = b.year_id
        and s.team_id = b.team_id
),

-- join salaries to pitchers
pitcher_salaries as (
    select
        s.player_id,
        s.year_id,
        s.team_id,
        s.salary,
        p.first_name,
        p.last_name,
        p.birth_country,
        cast(null as int64)                         as games,
        cast(null as int64)                         as at_bats,
        cast(null as int64)                         as hits,
        cast(null as int64)                         as home_runs,
        cast(null as int64)                         as rbi,
        cast(null as float64)                       as obp,
        cast(null as float64)                       as slg,
        cast(null as float64)                       as ops,
        cast(null as string)                        as ops_tier,
        'Pitcher'                                   as player_type,
        p.era_calculated,
        p.innings_pitched,
        p.whip,
        p.pitching_efficiency_proxy,
        p.era_tier,
        cast(null as float64)                       as ops_per_million,
        
        -- efficiency: lower ERA per $1M is better
        round(
            safe_divide(p.era_calculated, s.salary / 1000000), 4
        )                                           as era_per_million

    from salaries s
    inner join pitching p
        on s.player_id = p.player_id
        and s.year_id = p.year_id
        and s.team_id = p.team_id
),

final as (
    select * from batter_salaries
    union all
    select * from pitcher_salaries
)

select * from final