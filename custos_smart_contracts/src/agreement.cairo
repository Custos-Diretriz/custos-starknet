use starknet::ContractAddress;

#[starknet::interface]
pub trait IAgreement<TContractState> {
    fn createAgreement(
        ref self: TContractState,
        content: felt252,
        secondPartyAddress: ContractAddress,
        firstPartyValidId: felt252,
        secondPartyValidId: felt252
    ) -> u256;
    fn getAgreementDetails(self: @TContractState, id: u256) -> Agreement::LegalAgreement;
    fn getAllAgreements(self: @TContractState) -> Array<Agreement::LegalAgreement>;
    fn getUserAgreements(self: @TContractState) -> Array<Agreement::LegalAgreement>;
    fn signAgreement(ref self: TContractState, agreementId: u256);
}

#[starknet::contract]
pub mod Agreement {
    use starknet::ContractAddress;
    use starknet::{get_caller_address, storage_access};

    #[storage]
    struct Storage {
        agreement_count: u256,
        agreements: LegacyMap<u256, LegalAgreement>,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct LegalAgreement {
        creator: ContractAddress,
        content: felt252,
        second_party_address: ContractAddress,
        first_party_valid_id: felt252,
        second_party_valid_id: felt252,
        signed: bool,
        validate_signature: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AgreementCreated: AgreementCreated,
        AgreementSigned: AgreementSigned,
        AgreementValid: AgreementValid,
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
        fn createAgreement(
            ref self: ContractState,
            content: felt252,
            secondPartyAddress: ContractAddress,
            firstPartyValidId: felt252,
            secondPartyValidId: felt252
        ) -> u256 {
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
            self.agreement_count.write(self.agreement_count.read() + 1);

            self.emit(AgreementCreated { agreement_id, creator: caller_address, content, });

            return agreement_id;
        }

        fn getAgreementDetails(self: @ContractState, id: u256) -> LegalAgreement {
            return self.agreements.read(id);
        }

        fn getAllAgreements(self: @ContractState) -> Array<LegalAgreement> {
            let mut all_agreements: Array<LegalAgreement> = ArrayTrait::new();

            let mut count = self.agreement_count.read();
            let mut counter = 0;

            while counter < count
                + 1 {
                    all_agreements.append(self.agreements.read(counter));
                    counter + 1;
                };

            return all_agreements;
        }

        fn getUserAgreements(self: @ContractState) -> Array<LegalAgreement> {
            let caller_address = get_caller_address();
            let count = self.agreement_count.read();
            let mut user_agreements = ArrayTrait::<LegalAgreement>::new();
            let mut i = 0;

            while i < count
                + 1 {
                    let agreement = self.agreements.read(i);
                    if agreement.creator == caller_address
                        || agreement.second_party_address == caller_address {
                        user_agreements.append(agreement);
                    }
                    i + 1;
                };
            user_agreements
        }

        fn signAgreement(ref self: ContractState, agreementId: u256) {
            let mut agreement = self.agreements.read(agreementId);
            let caller_address = get_caller_address();

            if caller_address == agreement.creator
                || caller_address == agreement.second_party_address {
                agreement.signed = true;
                self.agreements.write(agreementId, self.agreements.read(agreementId));
            }
            self.emit(AgreementSigned { agreement_id: agreementId, signer: caller_address, });

            if agreement.signed {
                self
                    .emit(
                        AgreementValid {
                            agreement_id: agreementId,
                            first_party_id: agreement.first_party_valid_id,
                            second_party_id: agreement.second_party_valid_id,
                        }
                    );
            }
        }
    }
}

