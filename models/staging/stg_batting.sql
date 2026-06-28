with source as (
    select * from {{ source('raw', 'batting') }}
),

renamed as (
    select
        -- keys
        playerID                                    as player_id,
        yearID                                      as year_id,
        teamID                                      as team_id,
        lgID                                        as league_id,
        stint                                       as stint,

        -- counting stats
        G                                           as games,
        AB                                          as at_bats,
        R                                           as runs,
        H                                           as hits,
        `2B`                                        as doubles,
        `3B`                                        as triples,
        HR                                          as home_runs,
        RBI                                         as rbi,
        SB                                          as stolen_bases,
        CS                                          as caught_stealing,
        BB                                          as walks,
        SO                                          as strikeouts,

        -- rate stats (may be null in older records)
        IBB                                         as intentional_walks,
        HBP                                         as hit_by_pitch,
        SH                                          as sacrifice_hits,
        SF                                          as sacrifice_flies,
        GIDP                                        as grounded_into_dp

    from source
    where playerID is not null
    and yearID is not null
)

select * from renamed