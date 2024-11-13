use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress};
use starknet::contract_address::contract_address_const;

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
    let agreement_title = "Test Agreement";

    let caller: ContractAddress = starknet::contract_address_const::<0x100006789>();

    start_cheat_caller_address(agreement_contract_address, caller);
    let agreement_id = agreement_contract
        .create_agreement(
            content.clone(),
            second_party_address,
            first_party_valid_id.clone(),
            second_party_valid_id.clone(),
            agreement_title.clone()
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
    assert!(agreement_details.agreement_title == agreement_title, "wrong agreement title");
}

// Test for getting all agreements
#[test]
fn test_get_all_agreements() {
    let (_, agreement_contract) = setup_agreement();

    let content1 = "12345";
    let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
    let first_party_valid_id1 = "67890";
    let second_party_valid_id1 = "54321";
    let agreement_title1 = "Test Agreement 1";

    let content2 = "98765";
    let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
    let first_party_valid_id2 = "43210";
    let second_party_valid_id2 = "56789";
    let agreement_title2 = "Test Agreement 2";

    agreement_contract
        .create_agreement(
            content1,
            second_party_address1,
            first_party_valid_id1,
            second_party_valid_id1,
            agreement_title1
        );

    agreement_contract
        .create_agreement(
            content2,
            second_party_address2,
            first_party_valid_id2,
            second_party_valid_id2,
            agreement_title2
        );

    let all_agreements = agreement_contract.get_all_agreements();
    assert!(all_agreements.len() == 2, "wrong agreements count");
}
// Test for getting user agreements
#[test]
fn test_get_user_agreements() {
    let (agreement_contract_address, agreement_contract) = setup_agreement();

    let user: ContractAddress = contract_address_const::<'user'>();

    let content1 = "12345";
    let second_party_address1: ContractAddress = contract_address_const::<'second_party1'>();
    let first_party_valid_id1 = "67890";
    let second_party_valid_id1 = "54321";
    let agreement_title1 = "Test Agreement 1";

    let content2 = "98765";
    let second_party_address2: ContractAddress = contract_address_const::<'second_party2'>();
    let first_party_valid_id2 = "43210";
    let second_party_valid_id2 = "56789";
    let agreement_title2 = "Test Agreement 2";

    start_cheat_caller_address(agreement_contract_address, user);
    agreement_contract
        .create_agreement(
            content1,
            second_party_address1,
            first_party_valid_id1,
            second_party_valid_id1,
            agreement_title1
        );

    agreement_contract
        .create_agreement(
            content2,
            second_party_address2,
            first_party_valid_id2,
            second_party_valid_id2,
            agreement_title2
        );

    let user_agreements = agreement_contract.get_user_agreements(user);
    stop_cheat_caller_address(agreement_contract_address);

    assert!(user_agreements.len() == 2, "wrong user agreement length");
}
// Test for validating an agreement should when called by a wrong caller
#[test]
#[should_panic(expected: 'unauthorized caller')]
fn test_validate_agreement_should_panic_on_wrong_caller() {
    let (_, agreement_contract) = setup_agreement();

    let content = "12345";
    let second_party_address: ContractAddress = contract_address_const::<0x123626789>();
    let first_party_valid_id = "67890";
    let second_party_valid_id = "54321";
    let agreement_title = "Test Agreement";

    let agreement_id = agreement_contract
        .create_agreement(
            content,
            second_party_address,
            first_party_valid_id,
            second_party_valid_id,
            agreement_title
        );

    agreement_contract.validate_agreement(agreement_id);
}

// Test for validating an agreement: should be successful
#[test]
fn test_validate_agreement() {
    let (agreement_contract_address, agreement_contract) = setup_agreement();

    let content = "12345";
    let second_party_address: ContractAddress = contract_address_const::<0x123626789>();
    let first_party_valid_id = "67890";
    let second_party_valid_id = "54321";
    let agreement_title = "Test Agreement";

    let agreement_id = agreement_contract
        .create_agreement(
            content,
            second_party_address,
            first_party_valid_id,
            second_party_valid_id,
            agreement_title
        );

    start_cheat_caller_address(agreement_contract_address, second_party_address);
    agreement_contract.validate_agreement(agreement_id);
    stop_cheat_caller_address(agreement_contract_address);

    let validated_agreement = agreement_contract.get_agreement_details(agreement_id);

    assert!(validated_agreement.validate_signature == true, "wrong signature value");
}

