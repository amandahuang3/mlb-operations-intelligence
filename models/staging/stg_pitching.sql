with source as (
    select * from {{ source('raw', 'pitching') }}
),

renamed as (
    select
        -- keys
        playerID                                    as player_id,
        yearID                                      as year_id,
        teamID                                      as team_id,
        lgID                                        as league_id,
        stint                                       as stint,

        -- results
        W                                           as wins,
        L                                           as losses,
        G                                           as games,
        GS                                          as games_started,
        CG                                          as complete_games,
        SHO                                         as shutouts,
        SV                                          as saves,
        IPouts                                      as ip_outs,

        -- performance
        H                                           as hits_allowed,
        ER                                          as earned_runs,
        HR                                          as hr_allowed,
        BB                                          as walks,
        SO                                          as strikeouts,
        ERA                                         as era,

        -- advanced
        IBB                                         as intentional_walks,
        WP                                          as wild_pitches,
        HBP                                         as hit_batters,
        BK                                          as balks,
        BFP                                         as batters_faced,
        GF                                          as games_finished,
        R                                           as runs_allowed

    from source
    where playerID is not null
    and yearID is not null
)

select * from renamed