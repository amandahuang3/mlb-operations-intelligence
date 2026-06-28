with source as (
    select * from {{ source('raw', 'fielding') }}
),

renamed as (
    select
        -- keys
        playerID                                    as player_id,
        yearID                                      as year_id,
        teamID                                      as team_id,
        lgID                                        as league_id,
        POS                                         as position,
        stint                                       as stint,

        -- stats
        G                                           as games,
        GS                                          as games_started,
        InnOuts                                     as inn_outs,
        PO                                          as putouts,
        A                                           as assists,
        E                                           as errors,
        DP                                          as double_plays,
        ZR                                          as zone_rating

    from source
    where playerID is not null
    and yearID is not null
    and POS is not null
)

select * from renamed