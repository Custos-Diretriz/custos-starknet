use starknet::ContractAddress;

#[starknet::interface]
pub trait IAgreement<TContractState> {
    fn create_agreement(
        ref self: TContractState,
        content: ByteArray,
        secondPartyAddress: ContractAddress,
        firstPartyValidId: ByteArray,
        secondPartyValidId: ByteArray
    ) -> u256;
    fn get_agreement_details(self: @TContractState, id: u256) -> Agreement::LegalAgreement;
    fn get_all_agreements(self: @TContractState) -> Array<Agreement::LegalAgreement>;
    fn get_user_agreements(
        self: @TContractState, address: ContractAddress
    ) -> Array<Agreement::LegalAgreement>;
    fn validate_agreement(ref self: TContractState, agreementId: u256);
}

#[starknet::contract]
pub mod Agreement {
    use starknet::ContractAddress;
    use starknet::{get_caller_address, storage_access};

    #[storage]
    struct Storage {
        agreement_count: u256,
        agreements: LegacyMap<u256, LegalAgreement>,
        admin: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct LegalAgreement {
        creator: ContractAddress,
        content: ByteArray,
        second_party_address: ContractAddress,
        first_party_valid_id: ByteArray,
        second_party_valid_id: ByteArray,
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
        creator: ContractAddress
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
        first_party_id: ByteArray,
        second_party_id: ByteArray,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin)
    }

    #[abi(embed_v0)]
    impl AgreementContract of super::IAgreement<ContractState> {
        fn create_agreement(
            ref self: ContractState,
            content: ByteArray,
            secondPartyAddress: ContractAddress,
            firstPartyValidId: ByteArray,
            secondPartyValidId: ByteArray
        ) -> u256 {
            let agreement_id = self.agreement_count.read() + 1;
            let caller_address = get_caller_address();

            let newagreement = LegalAgreement {
                creator: caller_address,
                content,
                second_party_address: secondPartyAddress,
                first_party_valid_id: firstPartyValidId,
                second_party_valid_id: secondPartyValidId,
                signed: true,
                validate_signature: false,
            };

            self.agreements.write(agreement_id, newagreement);
            self.agreement_count.write(self.agreement_count.read() + 1);

            self.emit(AgreementCreated { agreement_id, creator: caller_address, });
            self.emit(AgreementSigned { agreement_id: agreement_id, signer: caller_address, });

            return agreement_id;
        }

        fn get_agreement_details(self: @ContractState, id: u256) -> LegalAgreement {
            return self.agreements.read(id);
        }

        fn get_all_agreements(self: @ContractState) -> Array<LegalAgreement> {
            // assert(get_caller_address() == self.admin.read(), 'Not Admin'); 
            let mut all_agreements: Array<LegalAgreement> = ArrayTrait::new();

            let mut count = self.agreement_count.read();
            let mut counter = 1;

            while counter < count
                + 1 {
                    all_agreements.append(self.agreements.read(counter));
                    counter +=1;
                };

            return all_agreements;
        }

        fn get_user_agreements(
            self: @ContractState, address: ContractAddress
        ) -> Array<LegalAgreement> {
            let count = self.agreement_count.read();
            let mut user_agreements: Array<LegalAgreement> = ArrayTrait::new();
            let mut i = 1;

            while i < count
                + 1 {
                    let agreement = self.agreements.read(i);
                    if agreement.creator == address || agreement.second_party_address == address {
                        user_agreements.append(agreement);
                    }
                    i += 1;
                };
            user_agreements
        }

        fn validate_agreement(ref self: ContractState, agreementId: u256) {
            let mut agreement = self.agreements.read(agreementId);
            let caller_address = get_caller_address();
            assert(caller_address == agreement.second_party_address, 'unauthorized caller');

            if caller_address == agreement.second_party_address {
                agreement.validate_signature = true;

                self.agreements.write(agreementId, self.agreements.read(agreementId));
            };
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

