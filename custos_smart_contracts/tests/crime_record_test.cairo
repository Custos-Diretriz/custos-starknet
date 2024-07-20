use snforge_std::{declare, ContractClassTrait};
use starknet::{ContractAddress, contract_address_const, deploy_syscall, SysCallResultTrait};
use custos_smart_contracts::crime_record::{
    CrimeRecord, ICrimeWitnessDispatcher, ICrimeWitnessDispatcherTrait
};

// fn deploy_crime_recorder() -> (ICrimeWitnessDispatcher, ContractAddress) {
//     let contract = declare("CrimeRecord").unwrap();
//     let owner: ContractAddress = contract_address_const::<'owner'>();
//     let constructor_calldata = array![owner.into()];
//     let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
//     let dispatcher = ICrimeWitnessDispatcher {contract_address};
//     (dispatcher, contract_address)
// }

fn setup_recorder() -> ICrimeWitnessDispatcher {
    let owner: ContractAddress = contract_address_const::<'owner'>();
    let (address, _) = deploy_syscall(
        CrimeRecord::TEST_CLASS_HASH.try_into().unwrap(), 0, array![owner.into()].span(), false
    )
        .unwrap_syscall();
    ICrimeWitnessDispatcher { contract_address: address }
}

#[test]
fn test_constructor() {
    let dispatcher = setup_recorder();
    assert(dispatcher.owner(), owner());
}
