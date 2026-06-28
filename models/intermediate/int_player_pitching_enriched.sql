with pitching as (
    select * from {{ ref('stg_pitching') }}
),

people as (
    select
        player_id,
        first_name,
        last_name,
        birth_country,
        throw_hand
    from {{ ref('stg_people') }}
),

-- aggregate stints same as batting
pitching_aggregated as (
    select
        player_id,
        year_id,
        max(team_id)                                as team_id,
        max(league_id)                              as league_id,
        sum(wins)                                   as wins,
        sum(losses)                                 as losses,
        sum(games)                                  as games,
        sum(games_started)                          as games_started,
        sum(saves)                                  as saves,
        sum(ip_outs)                                as ip_outs,
        sum(hits_allowed)                           as hits_allowed,
        sum(earned_runs)                            as earned_runs,
        sum(hr_allowed)                             as hr_allowed,
        sum(walks)                                  as walks,
        sum(strikeouts)                             as strikeouts,
        sum(batters_faced)                          as batters_faced,
        sum(runs_allowed)                           as runs_allowed
    from pitching
    group by player_id, year_id
),

with_metrics as (
    select
        player_id,
        year_id,
        team_id,
        league_id,
        wins,
        losses,
        games,
        games_started,
        saves,
        ip_outs,
        hits_allowed,
        earned_runs,
        hr_allowed,
        walks,
        strikeouts,
        batters_faced,

        -- innings pitched as decimal
        round(ip_outs / 3, 1)                       as innings_pitched,

        -- ERA = (ER / IP) * 9
        round(
            safe_divide(earned_runs, ip_outs / 3) * 9, 2
        )                                           as era_calculated,

        -- K/9 = (SO / IP) * 9
        round(
            safe_divide(strikeouts, ip_outs / 3) * 9, 2
        )                                           as k_per_9,

        -- BB/9 = (BB / IP) * 9
        round(
            safe_divide(walks, ip_outs / 3) * 9, 2
        )                                           as bb_per_9,

        -- WHIP = (BB + H) / IP
        round(
            safe_divide(walks + hits_allowed, ip_outs / 3), 3
        )                                           as whip,

        -- K/BB ratio
        round(
            safe_divide(strikeouts, nullif(walks, 0)), 2
        )                                           as k_bb_ratio

    from pitching_aggregated
    where ip_outs > 0
),

-- Custom pitching performance index
final as (
    select
        p.player_id,
        p.year_id,
        p.team_id,
        p.league_id,
        pp.first_name,
        pp.last_name,
        pp.birth_country,
        pp.throw_hand,
        p.wins,
        p.losses,
        p.games,
        p.games_started,
        p.saves,
        p.innings_pitched,
        p.hits_allowed,
        p.earned_runs,
        p.hr_allowed,
        p.walks,
        p.strikeouts,
        p.era_calculated,
        p.k_per_9,
        p.bb_per_9,
        p.whip,
        p.k_bb_ratio,

        -- pitcher efficiency proxy for payroll analysis
        -- higher is better: high K/9, low BB/9, low ERA
        round(
            safe_divide(p.k_per_9, nullif(p.bb_per_9, 0))
            * safe_divide(1, nullif(p.era_calculated, 0))
            * 10, 4
        )                                           as pitching_efficiency_proxy,

        -- role
        case
            when p.games_started >= 10 then 'Starter'
            when p.saves >= 10 then 'Closer'
            else 'Reliever'
        end                                         as pitcher_role,

        -- quality tier
        case
            when p.innings_pitched < 50 then 'Insufficient IP'
            when p.era_calculated <= 3.00 then 'Elite'
            when p.era_calculated <= 3.75 then 'Above Average'
            when p.era_calculated <= 4.50 then 'Average'
            else 'Below Average'
        end                                         as era_tier

    from with_metrics p
    left join people pp
        on p.player_id = pp.player_id
)

select * from final