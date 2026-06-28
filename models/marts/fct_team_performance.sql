with team_performance as (
    select * from {{ ref('int_team_season_performance') }}
),

final as (
    select
        -- keys
        team_id,
        year_id,
        league_id,
        division_id,
        franchise_id,
        team_name,
        baseball_era,

        -- win/loss record
        wins,
        losses,
        games_played,
        win_pct,

        -- offense
        runs_scored,
        home_runs,
        walks,
        strikeouts,
        runs_per_game,

        -- pitching/defense
        runs_allowed,
        era,
        saves,
        walks_allowed,
        strikeouts_by_pitchers,
        runs_allowed_per_game,

        -- derived
        run_differential,

        -- postseason
        made_postseason,
        won_world_series,

        -- performance profile for Q1 analysis
        case
            when era <= 3.80 and runs_scored >= 750 then 'Elite Pitching + Elite Offense'
            when era <= 3.80 and runs_scored < 750  then 'Elite Pitching + Average Offense'
            when era > 3.80  and runs_scored >= 750 then 'Average Pitching + Elite Offense'
            else 'Average Pitching + Average Offense'
        end                                         as team_profile,

        -- win tier
        case
            when win_pct >= 0.600 then 'Elite (90+ wins pace)'
            when win_pct >= 0.540 then 'Contender (85+ wins pace)'
            when win_pct >= 0.480 then 'Fringe (75+ wins pace)'
            else 'Rebuilding (under 75 wins pace)'
        end                                         as win_tier

    from team_performance
    -- scope to modern era for cleaner analysis
    -- historical data still exists for deeper dives
    where year_id >= 1985
)

select * from final