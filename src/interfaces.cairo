use starknet::ContractAddress;
use crate::agreement::Agreement;

#[starknet::interface]
pub trait IAgreement<TContractState> {
    fn create_agreement(
        ref self: TContractState,
        content: ByteArray,
        second_party_address: ContractAddress,
        first_party_valid_id: ByteArray,
        second_party_valid_id: ByteArray,
        agreement_title: ByteArray,
    ) -> u256;
    fn get_agreement_details(self: @TContractState, id: u256) -> Agreement::LegalAgreement;
    fn get_all_agreements(self: @TContractState) -> Array<Agreement::LegalAgreement>;
    fn get_user_agreements(
        self: @TContractState, address: ContractAddress
    ) -> Array<Agreement::LegalAgreement>;
    fn validate_agreement(ref self: TContractState, agreementId: u256);
}


#[starknet::interface]
pub trait ICrimeWitness<TContractState> {
    fn crime_record(ref self: TContractState, uri: ByteArray, data: Span<felt252>) -> bool;
    fn get_token_uri(self: @TContractState, id: u256) -> ByteArray;
    fn store_cid(ref self: TContractState, file_cid: ByteArray);
    fn get_cid(self: @TContractState, account: ContractAddress) -> Array<ByteArray>;
    fn get_all_user_uploads(self: @TContractState, user: ContractAddress) -> Array<u256>;
}

#[starknet::interface]
pub trait ICrimeWitnessTest<TContractState> {
    fn crime_record(ref self: TContractState, uri: ByteArray, data: Span<felt252>) -> bool;
    fn get_token_uri(self: @TContractState, id: u256) -> ByteArray;
    fn get_all_user_uploads(self: @TContractState, user: ContractAddress) -> Array<u256>;
    fn store_cid(ref self: TContractState, file_cid: ByteArray);
    fn get_cid(self: @TContractState, account: ContractAddress) -> Array<ByteArray>;

    fn owner(self: @TContractState) -> ContractAddress;

    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn token_uri(self: @TContractState, token_id: u256) -> ByteArray;
}

#[starknet::interface]
pub trait ICustosSafe<TContractState> {
    fn upload_cid(ref self: TContractState, file_cid: ByteArray);
    fn batch_upload_cid(ref self: TContractState, cids: Array<ByteArray> );
    fn get_cid(self: @TContractState, account: ContractAddress) -> Array<ByteArray>;
    /// @returns group id
    fn create_group(ref self: TContractState, group_title: ByteArray, group_id: u256) -> u256;
    fn delete_group(ref self: TContractState, group_id: u256);
    fn add_to_group(ref self: TContractState, group_id: u256, cid: ByteArray) -> u64;
    fn remove_from_group(ref self: TContractState, group_id: u256, cid: ByteArray) -> ByteArray;
    fn get_group(self: @TContractState, group_id: u256) -> Array<ByteArray>;
}

#[starknet::interface]
pub trait ICustosSafeTest<TContractState> {
    fn upload_cid(ref self: TContractState, file_cid: ByteArray);
    fn batch_upload_cid(ref self: TContractState, cids: Array<ByteArray> );
    fn get_cid(self: @TContractState, account: ContractAddress) -> Array<ByteArray>;
    /// @returns group id
    fn create_group(ref self: TContractState, group_title: ByteArray, group_id: u256) -> u256;
    fn delete_group(ref self: TContractState, group_id: u256);
    fn add_to_group(ref self: TContractState, group_id: u256, cid: ByteArray) -> u64;
    fn remove_from_group(ref self: TContractState, group_id: u256, cid: ByteArray) -> ByteArray;
    fn get_group(self: @TContractState, group_id: u256) -> Array<ByteArray>;

    fn owner(self: @TContractState) -> ContractAddress;

}