use custos_smart_contracts::interfaces::{ICustosSafeTestDispatcher, ICustosSafeTestDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address
};
use starknet::{ClassHash, ContractAddress, contract_address_const, get_caller_address};

// Helper function to deploy the contract
fn deploy_contract(owner: ContractAddress) -> (ICustosSafeTestDispatcher, ContractAddress) {
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(owner.into());

    let contract = declare("CustosSafe").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let dispatcher = ICustosSafeTestDispatcher { contract_address };
    (dispatcher, contract_address)
}

#[test]
fn test_constructor() {
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Assert
    let actual_owner = dispatcher.owner();
    assert(actual_owner == owner, 'Not Owner');
}

#[test]
fn test_upload_cid() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Execute
    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    start_cheat_caller_address(contract_address, caller);
    dispatcher.upload_cid(cid.clone());
    stop_cheat_caller_address(contract_address);

    // Assert
    let cids = dispatcher.get_cid(caller);
    assert(cids.len() == 1, 'CID was not uploaded');
    assert(cids.at(0) == @cid, 'Uploaded CID incorrect');
}

#[test]
fn test_batch_upload_cid() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Execute
    let cid1: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    let cid2: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";
    let cids: Array<> = array![cid1.clone(), cid2.clone()];

    start_cheat_caller_address(contract_address, caller);
    dispatcher.batch_upload_cid(cids.clone());
    stop_cheat_caller_address(contract_address);

    // Assert
    let uploaded_cids = dispatcher.get_cid(caller);
    assert!(uploaded_cids.len() == 2, "Batch CIDs were not uploaded");
    assert!(uploaded_cids.at(0) == @cid1, "Uploaded CID1 is incorrect");
    assert!(uploaded_cids == cids, "Uploaded CID2 is incorrect");
}

// #[test]
fn test_get_cid() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Prepare data
    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.upload_cid(cid.clone());
    stop_cheat_caller_address(contract_address);

    // Assert
    let uploaded_cids = dispatcher.get_cid(caller);
    assert(uploaded_cids.len() == 1, 'CID not uploaded');
    assert(uploaded_cids.at(0) == @cid, 'Uploaded CID incorrect');
}

#[test]
#[should_panic(expected: "no cid for user")]
fn test_get_cid_panics_when_no_cid_for_user() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.get_cid(caller);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_create_group() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Execute
    let group_title: ByteArray = "group v";
    let group_id: u256 = 1_u256;

    start_cheat_caller_address(contract_address, caller);
    let actual_group_id = dispatcher.create_group(group_title.clone(), group_id);
    stop_cheat_caller_address(contract_address);

    // Assert
    assert(actual_group_id == group_id, 'Group ID incorrect');
}

#[test]
fn test_delete_group() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Prepare data
    let group_title: ByteArray = "group one";
    let group_id: u256 = 1_u256;

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.create_group(group_title, group_id);
    dispatcher.delete_group(group_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_add_to_group() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Prepare data
    let group_title: ByteArray = "group one";
    let group_id: u256 = 1_u256;
    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.create_group(group_title, group_id);
    let cid_count = dispatcher.add_to_group(group_id, cid.clone());
    assert(cid_count == 1, 'incorrect CID len');
    stop_cheat_caller_address(contract_address);

    // Assert
    let cids = dispatcher.get_group(group_id);
    assert(cids.len() == 1, 'CID not added to group');
    assert(cids.at(0) == @cid, 'Uploaded CID incorrect');
}

#[test]
fn test_remove_from_group() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Prepare data
    let group_title: ByteArray = "group one";
    let group_id: u256 = 1_u256;
    let cid1: ByteArray = "test_cid1";
    let cid2: ByteArray = "test_cid2";

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.create_group(group_title, group_id);
    dispatcher.add_to_group(group_id, cid1.clone());
    dispatcher.add_to_group(group_id, cid2.clone());
    stop_cheat_caller_address(contract_address);

    let cids = dispatcher.get_group(group_id);
    assert(cids.len() == 2, 'incorrect CID count');
    
    start_cheat_caller_address(contract_address, caller);
    let removed = dispatcher.remove_from_group(group_id, cid1.clone());
    assert(removed == "", 'CID not removed');
    stop_cheat_caller_address(contract_address);

    // Assert
    let cids = dispatcher.get_group(group_id);
    assert(cids.len() == 1, 'CID was not removed from group');
    assert(cids.at(0) == @cid2, 'Uploaded CID is incorrect');
}

#[test]
fn test_get_group() {
    // Setup
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let (dispatcher, contract_address) = deploy_contract(owner);

    // Prepare data
    let group_title: ByteArray = "group one";
    let group_id: u256 = 1_u256;
    let cid: ByteArray = "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6";

    // Execute
    start_cheat_caller_address(contract_address, caller);
    dispatcher.create_group(group_title, group_id);
    dispatcher.add_to_group(group_id, cid.clone());
    stop_cheat_caller_address(contract_address);

    // Assert
    let cids = dispatcher.get_group(group_id);
    assert(cids.len() == 1, 'CID was not added to group');
    assert(cids.at(0) == @cid, 'Uploaded CID is incorrect');
}

