use starknet::ContractAddress;
use starknet::{get_caller_address, storage_access};

#[starknet::interface]
trait IAgreement<TContractState> {
    fn createAgreement(ref self: TContractState, content: felt252, secondPartyAddress: ContractAddress, firstPartyValidId: felt252, secondPartyValidId: felt252) -> u256;
    fn getAgreementDetails(self: @TContractState, id: u256) -> LegalAgreement;
    fn getAllAgreements(self: @TContractState) -> Array<LegalAgreement>;
    fn getUserAgreements(self: @TContractState) -> Array<LegalAgreement>;
    fn signAgreement(ref self: TContractState, agreementId: u256);
}

#[derive(Copy, Clone)]
struct LegalAgreement {
    creator: ContractAddress,
    content: felt252,
    second_party_address: ContractAddress,
    first_party_valid_id: felt252,
    second_party_valid_id: felt252,
    signed: bool,
    validate_signature: bool,
}

#[starknet::contract]
mod agreementContract {
    use starknet::ContractAddress;
    use starknet::{get_caller_address, storage_access};
    use super::LegalAgreement;
    use super;

    #[storage]
    struct Storage {
        agreement_count: u256,
        agreements: LegacyMap<u256, LegalAgreement>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AgreementCreated: AgreementCreated,
        AgreementSigned: AgreementSigned,
        AgreementValid: AgreementValid
    }

    #[derive(Drop, starknet::Event)]
    struct AgreementCreated {
        #[key]
        agreement_id: u256,
        creator: ContractAddress,
        content: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct AgreementSigned {
        #[key]
        agreement_id: u256, 
        signer: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AgreementValid {
        #[key]
        agreement_id: u256, 
        first_party_id: felt252,
        second_party_id: felt252,
    }

    #[abi(embed_v0)]
    impl AgreementContract of super::IAgreement<ContractState> {
        fn createAgreement(ref self: ContractState, content: felt252, secondPartyAddress: ContractAddress, firstPartyValidId: felt252, secondPartyValidId: felt252) -> u256 {
            let agreement_id = self.agreement_count.read();
            let caller_address = get_caller_address();

            let newagreement = LegalAgreement {
                creator: caller_address,
                content,
                second_party_address: secondPartyAddress,
                first_party_valid_id: firstPartyValidId,
                second_party_valid_id: secondPartyValidId,
                signed: false,
                validate_signature: false,
            };

            self.agreements.write(agreement_id, newagreement);
            self.agreement_count += 1;

            // AgreementCreated {
            //     agreement_id,
            //     creator: caller_address,
            //     content,
            // }.emit();

            return agreement_id;
        }

        fn getAgreementDetails(self: @ContractState, id: u256) -> LegalAgreement {
            return self.agreements.read(id);
        }

        fn getAllAgreements(self: @ContractState) -> Array<LegalAgreement> {
            let mut all_agreements = Array::new();
            for i in 0..self.agreement_count {
                all_agreements.push(self.agreements.read(i));
            }
            return all_agreements;
        }

        fn getUserAgreements(self: @ContractState) -> Array<LegalAgreement> {
            let caller_address = get_caller_address();
            let count = self.agreement_count.read();
            let mut user_agreements = ArrayTrait::<LegalAgreement>::new();
            for i in count {
                let agreement = self.agreements.read(i);
                if agreement.creator.read() == caller_address || agreement.second_party_address.read() == caller_address {
                    user_agreements.append(agreement);
                }
            }
            user_agreements
        }

        fn signAgreement(ref self: ContractState, agreementId: u256) {
            let mut agreement = self.agreements.read(agreementId);
            let caller_address = get_caller_address();

            if caller_address == agreement.creator || caller_address == agreement.second_party_address {
                self.agreement.signed.write(true);
                self.agreements.write(agreementId, agreement);
            }

                // AgreementSigned {
                //     agreement_id: agreementId,
                //     signer: caller_address,
                // }.emit();

                // if agreement.signed {
                //     AgreementValid {
                //         agreement_id: agreementId,
                //         first_party_id: agreement.first_party_valid_id,
                //         second_party_id: agreement.second_party_valid_id,
                //     }.emit();
                // }
            }
        }
    }

