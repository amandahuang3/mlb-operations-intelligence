with source as (
    select * from {{ source('raw', 'teams') }}
),

renamed as (
    select
        -- keys
        teamID                                      as team_id,
        yearID                                      as year_id,
        lgID                                        as league_id,
        divID                                       as division_id,
        franchID                                    as franchise_id,

        -- results
        W                                           as wins,
        L                                           as losses,
        G                                           as games_played,
        DivWin                                      as division_winner,
        WCWin                                       as wild_card_winner,
        LgWin                                       as league_winner,
        WSWin                                       as world_series_winner,

        -- offense
        R                                           as runs_scored,
        AB                                          as at_bats,
        H                                           as hits,
        HR                                          as home_runs,
        BB                                          as walks,
        SO                                          as strikeouts,

        -- pitching/defense
        RA                                          as runs_allowed,
        ER                                          as earned_runs,
        ERA                                         as era,
        CG                                          as complete_games,
        SHO                                         as shutouts,
        SV                                          as saves,
        IPouts                                      as ip_outs,
        HA                                          as hits_allowed,
        HRA                                         as hr_allowed,
        BBA                                         as walks_allowed,
        SOA                                         as strikeouts_by_pitchers,

        -- team info
        name                                        as team_name,
        park                                        as park_name

    from source
    where teamID is not null
    and yearID is not null
)

select * from renamed