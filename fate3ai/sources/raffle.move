module fate3ai::raffle {
    use fate3ai::fate::{mint_token, AppTokenCap, AdminCap};
    use sui::clock::{Clock, timestamp_ms};
    use std::string::String;

    public struct RaffleInfo has key{
        id: UID,
        name: String,
        description: String,
        ticket_cost: u64,
        prize: PrizeValidity,
        prize_prob: PrizeProb,
        refund_rate: u64,
    }

    public struct PrizeValidity has key, store{
        id: UID,
        grand_prize_duration: u64,
        second_prize_duration: u64,
        third_prize_duration: u64,
    }

    public struct PrizeProb has key, store{
        id: UID,
        grand_prize_weight: u64,
        second_prize_weight: u64,
        third_prize_weight: u64,
    }

    public struct RaffleNFT has key, store {
        id: UID,
        activetime: u64,  // Prize validity period (in days)
        factor: u64       // Prize multiplier factor
    }

    public fun create_raffle(
        _: &AdminCap,
        name: String,
        description: String,
        ticket_cost: u64,
        refund_rate: u64,
        grand_prize_duration: u64,
        second_prize_duration: u64,
        third_prize_duration: u64,
        grand_prize_weight: u64,
        second_prize_weight: u64,
        third_prize_weight: u64,
        ctx: &mut TxContext
    ){
        let prize_prob = PrizeProb {
            id: object::new(ctx),
            grand_prize_weight,
            second_prize_weight,
            third_prize_weight,
        };

        let prize_validity = PrizeValidity {
            id: object::new(ctx),
            grand_prize_duration,
            second_prize_duration,
            third_prize_duration,
        };

        let raffle = RaffleInfo {
            id: object::new(ctx),
            name,
            description,
            ticket_cost,
            prize: prize_validity,
            prize_prob,
            refund_rate,
        };

        transfer::share_object(raffle);
    }

    public fun set_raffle(
        _: &AdminCap,
        name: String,
        description: String,
        ticket_cost: u64,
        refund_rate: u64,
        grand_prize_duration: u64,
        second_prize_duration: u64,
        third_prize_duration: u64,
        grand_prize_weight: u64,
        second_prize_weight: u64,
        third_prize_weight: u64,
        raffle_info: &mut RaffleInfo,
        _: &mut TxContext
    ){
        raffle_info.name = name;
        raffle_info.description = description;
        raffle_info.ticket_cost = ticket_cost;
        raffle_info.refund_rate = refund_rate;
        let prize_validity = &mut raffle_info.prize;
        prize_validity.grand_prize_duration = grand_prize_duration;
        prize_validity.second_prize_duration = second_prize_duration;
        prize_validity.third_prize_duration = third_prize_duration;
        let prize_prob = &mut raffle_info.prize_prob;
        prize_prob.grand_prize_weight = grand_prize_weight;
        prize_prob.second_prize_weight = second_prize_weight;
        prize_prob.third_prize_weight = third_prize_weight;
    }

    // Lottery function to determine the prize based on weighted probability
    public fun lottery(
        time: &Clock,
        taro: vector<u64>,
        raffleinfo: &RaffleInfo,
        token_cap: &mut AppTokenCap,
        ctx: &mut TxContext
    ) {
        let taro_seed = sum(&taro);
        let time_seed = timestamp_ms(time) % 1000;
        let ctx_seed = ctx.epoch_timestamp_ms() % 1000;
        let final_seed = (taro_seed + time_seed) % ctx_seed;

        let final_rand = final_seed % 100;
        let prize = &raffleinfo.prize;
        let prize_prob = &raffleinfo.prize_prob;

        if (final_rand < prize_prob.grand_prize_weight){
            mint(prize.grand_prize_duration,ctx.sender(),ctx);
        }else if(final_rand < prize_prob.grand_prize_weight + prize_prob.second_prize_weight){
            mint(prize.second_prize_duration,ctx.sender(),ctx);
        }else if(final_rand < prize_prob.grand_prize_weight + prize_prob.second_prize_weight + prize_prob.third_prize_weight){
            mint(prize.third_prize_duration,ctx.sender(),ctx);
        }else{
            mint_token(token_cap,raffleinfo.refund_rate, ctx.sender(),ctx);
        }
    }

    // Function to get the prize details (validity period and factor)
    public fun get_activetime(
        rafflenft: &RaffleNFT
    ): (u64, u64) {
        (rafflenft.activetime, rafflenft.factor)
    }

    public fun sum(v: &vector<u64>): u64 {
        let mut total = 0;
        let len = vector::length(v);
        let mut i = 0;
        while (i < len) {
            total = total + *vector::borrow(v, i);
            i = i + 1;
        };
        total
    }

    // Mint a new RaffleNFT with the specified prize duration
    fun mint(
        activetime: u64,
        user: address,
        ctx: &mut TxContext
    ){
        let raffle_nft = RaffleNFT {
            id: object::new(ctx),
            activetime: activetime,
            factor: 2
        };
        transfer::public_transfer(raffle_nft, user);
    }
}
