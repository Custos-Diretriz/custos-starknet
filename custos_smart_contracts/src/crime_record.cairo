use starknet::ContractAddress;
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::token::erc20::ERC20Component;
use openzeppelin::token::erc20::ERC20HooksEmptyImpl;

#[starknet::interface]
trait ICrimeWitness<TContractState> {
    fn crime_record(ref self: TContractState, uri: felt252) -> bool;
}

#[starknet::contract]
mod CrimeRecord{
    use starknet::ContractAddress;
    #[storage]
    struct Storage {
        new_uri: felt252,
    }

    #[abi(embed_v0)]
    impl CrimeWitness of super::ICrimeWitness<ContractState> {
        fn crime_record(ref self: ContractState, uri: felt252) -> bool {
            self.new_uri.write(uri);
            true
        }
    }

   
}