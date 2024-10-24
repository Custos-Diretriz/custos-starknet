use snforge_std::{declare, ContractClassTrait};
use starknet::{ContractAddress};
use starknet::contract_address::contract_address_const;
use starknet::syscalls::deploy_syscall;
// use core::fmt::{Display, Formatter, Error};

// use custos_smart_contracts::agreement::{Agreement, IAgreementDispatcher,
// IAgreementDispatcherTrait};

// fn setup_agreement() -> IAgreementDispatcher {
//     let contract = declare("Agreement").unwrap();
//     let (contract_address, _) = contract.deploy(@array![]).unwrap();
//     let dispatcher = IAgreementDispatcher { contract_address };
//     dispatcher
// }
// Test for creating an agreement
// #[test]
// fn test_create_agreement() {
//     let contract = declare("Agreement").unwrap();
//     let (contract_address, _) = contract.deploy(@array![]).unwrap();
//     let dispatcher = IAgreementDispatcher { contract_address };
//     let content: felt252 = '12345';
//     let second_party_address: ContractAddress = contract_address_const::<'second_party'>();
//     let first_party_valid_id: felt252 = '67890';
//     let second_party_valid_id: felt252 = '54321';

//     let agreement_id = agreement
//         .createAgreement(
//             content, second_party_address, first_party_valid_id, second_party_valid_id
//         );

//     let created_agreement = agreement.getAgreementDetails(agreement_id);

//     assert_eq!(created_agreement.content, content);
//     assert_eq!(created_agreement.second_party_address, second_party_address);
//     assert_eq!(created_agreement.first_party_valid_id, first_party_valid_id);
//     assert_eq!(created_agreement.second_party_valid_id, second_party_valid_id);
//     assert_eq!(created_agreement.signed, false);
//     assert_eq!(created_agreement.validate_signature, false);
// }

Test for getting all agreements

#[derive(Debug)]
#[test]
fn test_get_all_agreements() {
    let mut formatter: Formatter = Default::default();
    let contract = declare("Agreement").unwrap();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = IAgreementDispatcher { contract_address };
    let content1: felt252 = '12345';
    let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
    let first_party_valid_id1: felt252 = '67890';
    let second_party_valid_id1: felt252 = '54321';

    let content2: felt252 = 98765;
    let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
    let first_party_valid_id2: felt252 = '43210';
    let second_party_valid_id2: felt252 = '56789';

    dispatcher
        .createAgreement(
            content1, second_party_address1, first_party_valid_id1, second_party_valid_id1
        );

    dispatcher
        .createAgreement(
            content2, second_party_address2, first_party_valid_id2, second_party_valid_id2
        );

    let all_agreements = dispatcher.getAllAgreements();
    write!(formatter, " {all_agreements}");
    println!("{:?}",formatter.buffer);
    // assert_eq!(all_agreements.len(), 2);
}

// Test for getting user agreements
#[test]
fn test_get_user_agreements() {
    let contract = declare("Agreement").unwrap();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = IAgreementDispatcher { contract_address };
    let _owner: ContractAddress = contract_address_const::<'owner'>();
    let content1: felt252 = '12345';
    let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
    let first_party_valid_id1: felt252 = '67890';
    let second_party_valid_id1: felt252 = '54321';

    let content2: felt252 = 98765;
    let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
    let first_party_valid_id2: felt252 = '43210';
    let second_party_valid_id2: felt252 = '56789';

    dispatcher
        .createAgreement(
            content1, second_party_address1, first_party_valid_id1, second_party_valid_id1
        );

    dispatcher
        .createAgreement(
            content2, second_party_address2, first_party_valid_id2, second_party_valid_id2
        );

    let user_agreements = dispatcher.getUserAgreements();
    assert_eq!(user_agreements.len(), 2);
}

Test for signing an agreement
#[test]
fn test_sign_agreement() {
    let contract = declare("Agreement").unwrap();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = IAgreementDispatcher { contract_address };
    let content: felt252 = '12345';
    let second_party_address: ContractAddress = contract_address_const::<'second_party'>();
    let first_party_valid_id: felt252 = '67890';
    let second_party_valid_id: felt252 = '54321';

    let agreement_id = dispatcher
        .createAgreement(
            content, second_party_address, first_party_valid_id, second_party_valid_id
        );

    dispatcher.signAgreement(agreement_id);
    let signed_agreement = dispatcher.getAgreementDetails(agreement_id);
assert_eq!(signed_agreement.signed, true);
assert_eq!(signed_agreement.validate_signature, false);
}


