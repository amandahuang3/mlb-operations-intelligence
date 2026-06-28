with teams as (
    select * from {{ ref('stg_teams') }}
),

final as (
    select
        -- one row per team per season
        team_id,
        year_id,
        league_id,
        division_id,
        franchise_id,
        team_name,
        park_name,

        -- active era flag
        case
            when year_id >= 2010 then 'Modern'
            when year_id >= 1990 then 'Contemporary'
            when year_id >= 1969 then 'Expansion'
            else 'Historical'
        end                                         as team_era

    from teams
)

select * from final