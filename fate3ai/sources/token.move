module fate3ai::fate{
    use std::{
        string::String
    };
    use sui::{
        coin::{Self, TreasuryCap},
        token::{Self, TokenPolicy, Token},
        table::{Self, Table},
        event::emit,
        url::new_unsafe_from_bytes
    };
    use fate3ai::profile::{Self, Profile};


    const DECIMALS: u8 = 0;
    const SYMBOLS: vector<u8> = b"FATE";
    const NAME: vector<u8> = b"FATE";
    const DESCRIPTION: vector<u8> = b"FATE3AI";
    const ICON_URL: vector<u8> = b"https://";

    const EWrongAmount: u64 = 0;

    public struct FATE has drop {}

    public struct AdminCap has key, store {
        id: UID,
    }

    public struct AppTokenCap has key {
        id: UID,
        cap: TreasuryCap<FATE>,
    }

    public struct PriceRecord has key {
        id: UID,
        prices: Table<String, u64>,
    }

    public struct BuyEvent has copy, drop {
        buyer: address,
        item: String,
        price: u64,
    }


    fun init(otw: FATE, ctx: &mut TxContext) {
        let deployer = ctx.sender();
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::public_transfer(admin_cap, deployer);

        let (treasury_cap, metadata) = coin::create_currency<FATE>(
            otw,
            DECIMALS,
            SYMBOLS,
            NAME,
            DESCRIPTION,
            option::some(new_unsafe_from_bytes(ICON_URL)),
            ctx
        );

        let (mut policy, cap) = token::new_policy<FATE>(
            &treasury_cap, ctx
        );

        let token_cap = AppTokenCap {
            id: object::new(ctx),
            cap: treasury_cap,
        };

        let price_record = PriceRecord {
            id: object::new(ctx),
            prices: table::new<String, u64>(ctx),
        };

        token::allow(&mut policy, &cap, token::spend_action(), ctx);


        token::share_policy<FATE>(policy);
        transfer::share_object(token_cap);
        transfer::share_object(price_record);
        transfer::public_transfer(cap, deployer);
        transfer::public_freeze_object(metadata);
    }

    public fun signin2earn(
        profile: &mut Profile,
        token_cap: &mut AppTokenCap,
        ctx: &mut TxContext
    ) {
        profile::signin(profile, ctx);
        let app_token = token::mint(&mut token_cap.cap, profile::dailypoints(profile), ctx);
        let req = token::transfer<FATE>(app_token, ctx.sender(), ctx);
        token::confirm_with_treasury_cap<FATE>(
            &mut token_cap.cap,
            req,
            ctx
        );
    }

    public fun buy(
        payment: Token<FATE>,
        price_record: &PriceRecord,
        item: String,
        token_prolicy: &mut TokenPolicy<FATE>,
        ctx: &mut TxContext
    ) {
        let price = &price_record.prices[item];
        assert!(token::value<FATE>(&payment) == *price, EWrongAmount);
        let req = token::spend(payment, ctx);
        token::confirm_request_mut(token_prolicy, req, ctx);
        emit(BuyEvent {
            buyer: ctx.sender(),
            item,
            price: *price,
        });
    }

    public fun split_token(
        token: &mut Token<FATE>,
        token_cap: &mut AppTokenCap,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let token_to_pay = token::split<FATE>(token, amount, ctx);

        let req = token::transfer<FATE>(token_to_pay, ctx.sender(), ctx);
        token::confirm_with_treasury_cap<FATE>(
            &mut token_cap.cap,
            req,
            ctx
        );
    }




    #[test_only]
    public fun init_for_testing_in_tests(ctx: &mut TxContext) {
        let otw = FATE {};
        init(otw, ctx);
    }

}
