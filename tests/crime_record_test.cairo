use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
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

#[test]
fn test_constructor() {
    let (_, crime_record_contract) = setup_crime_record();
    let owner: ContractAddress = contract_address_const::<0x123626789>();

    assert!(crime_record_contract.owner() == owner, "wrong owner");
    assert!(crime_record_contract.name() == "CrimeRecords", "wrong token name");
    assert!(crime_record_contract.symbol() == "CRD", "wrong token symbol");
}

#[test]
fn test_crime_record_success() {
    let (_, crime_record_contract) = setup_crime_record();

    let uri: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";

    let data = array![1234, 5678, 9101112].span();

    let new_crime_record = crime_record_contract.crime_record(uri, data);
    // assert!(crime_record, "crime record failed");
}

