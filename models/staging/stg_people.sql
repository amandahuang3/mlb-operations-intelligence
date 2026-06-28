with source as (
    select * from {{ source('raw', 'people') }}
),

renamed as (
    select
        -- keys
        playerID                                    as player_id,

        -- names
        nameFirst                                   as first_name,
        nameLast                                    as last_name,
        nameGiven                                   as given_name,

        -- bio
        birthYear                                   as birth_year,
        birthCountry                                as birth_country,
        birthState                                  as birth_state,
        birthCity                                   as birth_city,

        -- career dates
        debut                                       as mlb_debut_date,
        finalGame                                   as final_game_date,

        -- physical
        weight                                      as weight_lbs,
        height                                      as height_inches,
        bats                                        as bats_hand,
        throws                                      as throw_hand

    from source
    where playerID is not null
)

select * from renamed