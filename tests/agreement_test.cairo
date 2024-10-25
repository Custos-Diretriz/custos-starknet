use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, DeclareResult, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress};
use starknet::contract_address::contract_address_const;
use starknet::syscalls::deploy_syscall;
use core::fmt::{Display, Formatter, Error};

use custos_smart_contracts::agreement::Agreement;
use custos_smart_contracts::interfaces::{IAgreementDispatcher, IAgreementDispatcherTrait};

fn setup_agreement() -> (ContractAddress, IAgreementDispatcher) {
    let admin: ContractAddress = starknet::contract_address_const::<0x123626789>();

    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(admin.into());

    let contract = declare("Agreement").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let dispatcher = IAgreementDispatcher { contract_address };

    (contract_address, dispatcher)
}

// Test for creating an agreement
#[test]
fn test_create_agreement() {
    let (agreement_contract_address, agreement_contract) = setup_agreement();

    let content = "12345";
    let second_party_address: ContractAddress = contract_address_const::<0x123626789>();
    let first_party_valid_id = "67890";
    let second_party_valid_id = "54321";

    let caller: ContractAddress = starknet::contract_address_const::<0x100006789>();

    start_cheat_caller_address(agreement_contract_address, caller);
    let agreement_id = agreement_contract
        .create_agreement(
            content.clone(),
            second_party_address,
            first_party_valid_id.clone(),
            second_party_valid_id.clone()
        );
    stop_cheat_caller_address(agreement_contract_address);

    let agreement_details = agreement_contract.get_agreement_details(agreement_id);

    assert!(agreement_details.creator == caller, "wrong creator address");
    assert!(agreement_details.content == content, "content doesn't match");
    assert!(
        agreement_details.second_party_address == second_party_address,
        "second party address mismatch"
    );
    assert!(
        agreement_details.first_party_valid_id == first_party_valid_id, "first party id mismatch"
    );
    assert!(
        agreement_details.second_party_valid_id == second_party_valid_id, "second part id mismatch"
    );
    assert!(agreement_details.signed == true, "wrong signed value");
    assert!(agreement_details.validate_signature == false, "wrong signature value");
}

// Test for getting all agreements
#[test]
fn test_get_all_agreements() {
    let (_, agreement_contract) = setup_agreement();

    let content1 = "12345";
    let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
    let first_party_valid_id1 = "67890";
    let second_party_valid_id1 = "54321";

    let content2 = "98765";
    let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
    let first_party_valid_id2 = "43210";
    let second_party_valid_id2 = "56789";

    agreement_contract
        .create_agreement(
            content1, second_party_address1, first_party_valid_id1, second_party_valid_id1
        );

    agreement_contract
        .create_agreement(
            content2, second_party_address2, first_party_valid_id2, second_party_valid_id2
        );

    let all_agreements = agreement_contract.get_all_agreements();
    assert!(all_agreements.len() == 2, "wrong agreements count");
}
// Test for getting user agreements
// #[test]
// fn test_get_user_agreements() {
//     let contract = declare("Agreement").unwrap();
//     let (contract_address, _) = contract.deploy(@array![]).unwrap();
//     let dispatcher = IAgreementDispatcher { contract_address };
//     let _owner: ContractAddress = contract_address_const::<'owner'>();
//     let content1: felt252 = '12345';
//     let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
//     let first_party_valid_id1: felt252 = '67890';
//     let second_party_valid_id1: felt252 = '54321';

//     let content2: felt252 = 98765;
//     let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
//     let first_party_valid_id2: felt252 = '43210';
//     let second_party_valid_id2: felt252 = '56789';

//     dispatcher
//         .createAgreement(
//             content1, second_party_address1, first_party_valid_id1, second_party_valid_id1
//         );

//     dispatcher
//         .createAgreement(
//             content2, second_party_address2, first_party_valid_id2, second_party_valid_id2
//         );

//     let user_agreements = dispatcher.getUserAgreements();
//     assert_eq!(user_agreements.len(), 2);
// }

// Test for signing an agreement
// #[test]
// fn test_sign_agreement() {
//     let contract = declare("Agreement").unwrap();
//     let (contract_address, _) = contract.deploy(@array![]).unwrap();
//     let dispatcher = IAgreementDispatcher { contract_address };
//     let content: felt252 = '12345';
//     let second_party_address: ContractAddress = contract_address_const::<'second_party'>();
//     let first_party_valid_id: felt252 = '67890';
//     let second_party_valid_id: felt252 = '54321';

//     let agreement_id = dispatcher
//         .createAgreement(
//             content, second_party_address, first_party_valid_id, second_party_valid_id
//         );

//     dispatcher.signAgreement(agreement_id);
//     let signed_agreement = dispatcher.getAgreementDetails(agreement_id);
// assert_eq!(signed_agreement.signed, true);
// assert_eq!(signed_agreement.validate_signature, false);
// }


