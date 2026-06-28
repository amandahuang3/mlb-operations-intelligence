with people as (
    select * from {{ ref('stg_people') }}
),

-- find primary position: the position each player played most games at
fielding as (
    select
        player_id,
        -- group outfield positions together
        case
            when position in ('LF','CF','RF') then 'OF'
            else position
        end                                         as position,
        sum(games)                                  as games_at_position
    from {{ ref('stg_fielding') }}
    where position is not null
    group by player_id, position
),

-- rank positions by games played
position_ranked as (
    select
        player_id,
        position,
        games_at_position,
        row_number() over (
            partition by player_id
            order by games_at_position desc
        )                                           as position_rank
    from fielding
),

primary_position as (
    select
        player_id,
        position                                    as primary_position,
        games_at_position                           as games_at_primary_position
    from position_ranked
    where position_rank = 1
),

final as (
    select
        -- keys
        p.player_id,

        -- names
        p.first_name,
        p.last_name,
        concat(
            coalesce(p.first_name, ''), ' ',
            coalesce(p.last_name, '')
        )                                           as full_name,

        -- bio
        p.birth_country,
        p.birth_state,
        p.birth_city,
        p.birth_year,
        p.bats_hand,
        p.throw_hand,
        p.weight_lbs,
        p.height_inches,

        -- career
        p.mlb_debut_date,
        p.final_game_date,
        cast(
            substr(cast(p.mlb_debut_date as string), 1, 4)
            as int64
        )                                           as debut_year,

        -- position
        coalesce(pp.primary_position, 'Unknown')    as primary_position,
        pp.games_at_primary_position

    from people p
    left join primary_position pp
        on p.player_id = pp.player_id
)

select * from final