with batting as (
    select
        player_id,
        year_id,
        team_id,
        league_id,
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
        ops_tier,
        'Batter'                                    as player_type,
        cast(null as float64)                       as era_calculated,
        cast(null as float64)                       as innings_pitched,
        cast(null as float64)                       as whip,
        cast(null as float64)                       as k_per_9,
        cast(null as float64)                       as bb_per_9,
        cast(null as float64)                       as pitching_efficiency_proxy,
        cast(null as string)                        as pitcher_role,
        cast(null as string)                        as era_tier
    from {{ ref('int_player_batting_enriched') }}
    where at_bats >= 100
),

pitching as (
    select
        player_id,
        year_id,
        team_id,
        league_id,
        first_name,
        last_name,
        birth_country,
        cast(null as int64)                         as games,
        cast(null as int64)                         as at_bats,
        cast(null as int64)                         as hits,
        cast(null as int64)                         as home_runs,
        cast(null as int64)                         as rbi,
        cast(null as int64)                         as walks,
        cast(null as int64)                         as strikeouts,
        cast(null as float64)                       as obp,
        cast(null as float64)                       as slg,
        cast(null as float64)                       as ops,
        cast(null as string)                        as ops_tier,
        'Pitcher'                                   as player_type,
        era_calculated,
        innings_pitched,
        whip,
        k_per_9,
        bb_per_9,
        pitching_efficiency_proxy,
        pitcher_role,
        era_tier
    from {{ ref('int_player_pitching_enriched') }}
    where innings_pitched >= 30
),

combined as (
    select * from batting
    union all
    select * from pitching
),

final as (
    select
        c.player_id,
        c.year_id,
        c.team_id,
        c.league_id,
        c.first_name,
        c.last_name,
        c.birth_country,
        c.player_type,

        -- batting metrics
        c.games,
        c.at_bats,
        c.hits,
        c.home_runs,
        c.rbi,
        c.walks,
        c.strikeouts,
        c.obp,
        c.slg,
        c.ops,
        c.ops_tier,

        -- pitching metrics
        c.era_calculated,
        c.innings_pitched,
        c.whip,
        c.k_per_9,
        c.bb_per_9,
        c.pitching_efficiency_proxy,
        c.pitcher_role,
        c.era_tier,

        -- player dimension enrichment
        d.primary_position,
        d.debut_year,
        d.bats_hand,
        d.throw_hand

    from combined c
    left join {{ ref('dim_players') }} d
        on c.player_id = d.player_id
)

select * from final