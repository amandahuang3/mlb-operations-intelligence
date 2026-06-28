with salary_performance as (
    select * from {{ ref('int_player_salary_performance') }}
),

dim_players as (
    select * from {{ ref('dim_players') }}
),

-- team level payroll aggregations
team_payroll as (
    select
        team_id,
        year_id,
        sum(salary)                                 as total_team_payroll,
        count(distinct player_id)                   as roster_size,
        avg(salary)                                 as avg_player_salary
    from salary_performance
    group by team_id, year_id
),

final as (
    select
        -- keys
        sp.player_id,
        sp.year_id,
        sp.team_id,
        sp.first_name,
        sp.last_name,
        sp.birth_country,
        sp.player_type,

        -- position from dim
        dp.primary_position,
        dp.debut_year,

        -- salary
        sp.salary,
        round(sp.salary / 1000000, 3)               as salary_millions,

        -- team payroll context
        tp.total_team_payroll,
        round(tp.total_team_payroll / 1000000, 2)   as team_payroll_millions,
        round(
            safe_divide(sp.salary, tp.total_team_payroll) * 100, 2
        )                                           as pct_of_team_payroll,

        -- batting metrics
        sp.ops,
        sp.obp,
        sp.slg,
        sp.ops_tier,
        sp.at_bats,
        sp.home_runs,
        sp.rbi,

        -- pitching metrics
        sp.era_calculated,
        sp.innings_pitched,
        sp.whip,
        sp.era_tier,

        -- efficiency metrics
        sp.ops_per_million,
        sp.era_per_million,

        -- unified efficiency score for cross-player comparison
        -- batters: ops_per_million (higher = better)
        -- pitchers: inverse of era_per_million (lower ERA per $ = better)
        case
            when sp.player_type = 'Batter'
                then sp.ops_per_million
            when sp.player_type = 'Pitcher'
                then round(safe_divide(1, nullif(sp.era_per_million, 0)), 4)
            else null
        end                                         as efficiency_score,

        -- salary tier
        case
            when sp.salary >= 10000000  then 'Max Contract (10M+)'
            when sp.salary >= 5000000   then 'High Salary (5-10M)'
            when sp.salary >= 1000000   then 'Mid Salary (1-5M)'
            else 'League Minimum (under 1M)'
        end                                         as salary_tier

    from salary_performance sp
    left join dim_players dp
        on sp.player_id = dp.player_id
    left join team_payroll tp
        on sp.team_id = tp.team_id
        and sp.year_id = tp.year_id
)

select * from final