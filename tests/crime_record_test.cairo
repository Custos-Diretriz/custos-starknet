use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address
};
use starknet::{ContractAddress, contract_address_const};
use custos_smart_contracts::interfaces::{
    ICrimeWitnessTestDispatcher, ICrimeWitnessTestDispatcherTrait
};

fn setup_crime_record() -> (ContractAddress, ICrimeWitnessTestDispatcher) {
    let owner: ContractAddress = starknet::contract_address_const::<0x123626789>();

    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(owner.into());

    let contract = declare("CrimeRecord").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let dispatcher = ICrimeWitnessTestDispatcher { contract_address };

    (contract_address, dispatcher)
}

fn deploy_token_receiver() -> ContractAddress {
    let contract = declare("MyERC721Receiver").unwrap().contract_class();

    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();

    contract_address
}

#[test]
fn test_constructor() {
    let (_, crime_record_contract) = setup_crime_record();
    let owner: ContractAddress = contract_address_const::<0x123626789>();

    assert!(crime_record_contract.owner() == owner, "wrong owner");
    assert!(crime_record_contract.name() == "CrimeRecords", "wrong token name");
    assert!(crime_record_contract.symbol() == "CRD", "wrong token symbol");
}

#[test]
fn test_crime_record() {
    let (crime_record_address, crime_record_contract) = setup_crime_record();
    let token_receiver = deploy_token_receiver();

    let uri: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    let data = array![1234, 5678, 9101112].span();

    start_cheat_caller_address(crime_record_address, token_receiver);
    let new_crime_record = crime_record_contract.crime_record(uri, data);

    assert!(new_crime_record, "crime record failed");

    stop_cheat_caller_address(crime_record_address);
}

#[test]
fn test_get_token_uri() {
    let (crime_record_address, crime_record_contract) = setup_crime_record();
    let token_receiver = deploy_token_receiver();

    let uri: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    let data = array![1234, 5678, 9101112].span();

    start_cheat_caller_address(crime_record_address, token_receiver);
    crime_record_contract.crime_record(uri.clone(), data);

    let crime_uri = crime_record_contract.get_token_uri(1);

    assert!(crime_uri == uri, "wrong crime record uri");

    stop_cheat_caller_address(crime_record_address);
}

#[test]
fn test_get_all_user_uploads() {
    let (crime_record_address, crime_record_contract) = setup_crime_record();
    let token_receiver = deploy_token_receiver();

    let uri1: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    let data1 = array![1234, 5678, 9101112].span();

    let uri2: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68G8";
    let data2 = array![2234, 1122, 556611].span();

    start_cheat_caller_address(crime_record_address, token_receiver);
    crime_record_contract.crime_record(uri1.clone(), data1);
    crime_record_contract.crime_record(uri2.clone(), data2);

    let all_user_uploads = crime_record_contract.get_all_user_uploads(token_receiver);

    assert!(all_user_uploads.len() == 2, "wrong user upload count");

    stop_cheat_caller_address(crime_record_address);
}

#[test]
fn test_store_cid_and_get_cid() {
    let caller = contract_address_const::<'caller'>();
    let (crime_record_address, crime_record_contract) = setup_crime_record();

    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    start_cheat_caller_address(crime_record_address, caller);
    crime_record_contract.store_cid(cid);

    let cids = crime_record_contract.get_cid();
    assert!(cids.len() == 1, "expected 1 CID");
    stop_cheat_caller_address(crime_record_address);
}

#[test]
#[should_panic(expected: "no cid for user")]
fn test_store_cid_and_get_cid_unauthorized_caller() {
    let caller = contract_address_const::<'caller'>();
    let caller2 = contract_address_const::<'caller2'>();
    let (crime_record_address, crime_record_contract) = setup_crime_record();

    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    start_cheat_caller_address(crime_record_address, caller);
    crime_record_contract.store_cid(cid);
    stop_cheat_caller_address(crime_record_address);

    start_cheat_caller_address(crime_record_address, caller2);
    let cids = crime_record_contract.get_cid();
    assert!(cids.len() == 1, "expected 1 CID");
    stop_cheat_caller_address(crime_record_address);
}
