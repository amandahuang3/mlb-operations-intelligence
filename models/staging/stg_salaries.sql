with source as (
    select * from {{ source('raw', 'salaries') }}
),

renamed as (
    select
        -- keys
        playerID                                    as player_id,
        yearID                                      as year_id,
        teamID                                      as team_id,
        lgID                                        as league_id,

        -- metrics
        salary                                      as salary

    from source
    where playerID is not null
    and yearID is not null
    and salary is not null
)

select * from renamed