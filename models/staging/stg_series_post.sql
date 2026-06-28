with source as (
    select * from {{ source('raw', 'series_post') }}
),

renamed as (
    select
        -- keys
        yearID                                      as year_id,
        round                                       as series_round,
        teamIDwinner                                as winning_team_id,
        lgIDwinner                                  as winning_league_id,
        teamIDloser                                 as losing_team_id,
        lgIDloser                                   as losing_league_id,

        -- results
        wins                                        as winner_wins,
        losses                                      as winner_losses,
        ties                                        as ties

    from source
    where yearID is not null
)

select * from renamed