with teams as (
    select * from {{ ref('stg_teams') }}
),

postseason as (
    select distinct
        year_id,
        winning_team_id                             as team_id,
        true                                        as made_postseason,
        case 
            when series_round = 'WS' then true 
            else false 
        end                                         as won_world_series
    from {{ ref('stg_series_post') }}
    where series_round = 'WS'
),

team_postseason as (
    -- get all teams that appeared in any postseason series
    select distinct
        year_id,
        winning_team_id                             as team_id,
        true                                        as made_postseason
    from {{ ref('stg_series_post') }}
    
    union distinct
    
    select distinct
        year_id,
        losing_team_id                              as team_id,
        true                                        as made_postseason
    from {{ ref('stg_series_post') }}
),

final as (
    select
        -- keys
        t.team_id,
        t.year_id,
        t.league_id,
        t.division_id,
        t.franchise_id,
        t.team_name,

        -- win/loss
        t.wins,
        t.losses,
        t.games_played,
        round(
            safe_divide(t.wins, (t.wins + t.losses)), 3
        )                                           as win_pct,

        -- offense
        t.runs_scored,
        t.at_bats,
        t.hits,
        t.home_runs,
        t.walks,
        t.strikeouts,

        -- pitching/defense
        t.runs_allowed,
        t.era,
        t.saves,
        t.hits_allowed,
        t.hr_allowed,
        t.walks_allowed,
        t.strikeouts_by_pitchers,

        -- derived
        (t.runs_scored - t.runs_allowed)            as run_differential,
        round(
            safe_divide(t.runs_scored, t.games_played), 2
        )                                           as runs_per_game,
        round(
            safe_divide(t.runs_allowed, t.games_played), 2
        )                                           as runs_allowed_per_game,

        -- postseason flags
        case 
            when tp.made_postseason = true then true 
            else false 
        end                                         as made_postseason,
        case 
            when ws.won_world_series = true then true 
            else false 
        end                                         as won_world_series,

        -- era buckets for analysis (feature engineering)
        case
            when t.year_id < 1920 then 'Dead Ball Era'
            when t.year_id < 1942 then 'Live Ball Era'
            when t.year_id < 1961 then 'Integration Era'
            when t.year_id < 1977 then 'Expansion Era'
            when t.year_id < 1994 then 'Free Agency Era'
            when t.year_id < 2005 then 'Steroid Era'
            else 'Modern Era'
        end                                         as baseball_era

    from teams t
    left join team_postseason tp
        on t.team_id = tp.team_id
        and t.year_id = tp.year_id
    left join postseason ws
        on t.team_id = ws.team_id
        and t.year_id = ws.year_id
)

select * from final