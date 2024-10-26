#[starknet::contract]
pub mod Agreement {
    use UpgradeableComponent::InternalTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{UpgradeableComponent, interface::IUpgradeable};

    use starknet::{
        get_caller_address, ContractAddress, ClassHash,
        storage::{Map, StoragePointerWriteAccess, StoragePathEntry},
    };
    use crate::interfaces::IAgreement;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        agreement_count: u256,
        agreements: Map<u256, LegalAgreement>,
        admin: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct LegalAgreement {
        pub creator: ContractAddress,
        pub content: ByteArray,
        pub second_party_address: ContractAddress,
        pub first_party_valid_id: ByteArray,
        pub second_party_valid_id: ByteArray,
        pub signed: bool,
        pub validate_signature: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
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
        self.admin.write(admin);
        self.ownable.initializer(admin);
    }

    #[abi(embed_v0)]
    impl AgreementImpl of IAgreement<ContractState> {
        fn create_agreement(
            ref self: ContractState,
            content: ByteArray,
            second_party_address: ContractAddress,
            first_party_valid_id: ByteArray,
            second_party_valid_id: ByteArray
        ) -> u256 {
            let agreement_id = self.agreement_count.read() + 1;
            let caller_address = get_caller_address();

            let newagreement = LegalAgreement {
                creator: caller_address,
                content,
                second_party_address,
                first_party_valid_id,
                second_party_valid_id,
                signed: true,
                validate_signature: false,
            };

            self.agreements.entry(agreement_id).write(newagreement);
            self.agreement_count.write(self.agreement_count.read() + 1);

            self.emit(AgreementCreated { agreement_id, creator: caller_address, });
            self.emit(AgreementSigned { agreement_id: agreement_id, signer: caller_address, });

            agreement_id
        }

        fn get_agreement_details(self: @ContractState, id: u256) -> LegalAgreement {
            self.agreements.entry(id).read()
        }

        fn get_all_agreements(self: @ContractState) -> Array<LegalAgreement> {
            let mut all_agreements: Array<LegalAgreement> = ArrayTrait::new();

            let mut count = self.agreement_count.read();
            let mut counter = 1;

            while counter < count + 1 {
                all_agreements.append(self.agreements.entry(counter).read());
                counter += 1;
            };

            all_agreements
        }

        fn get_user_agreements(
            self: @ContractState, address: ContractAddress
        ) -> Array<LegalAgreement> {
            let count = self.agreement_count.read();
            let mut user_agreements: Array<LegalAgreement> = ArrayTrait::new();
            let mut i = 1;

            while i < count + 1 {
                let agreement = self.agreements.entry(i).read();
                if agreement.creator == address || agreement.second_party_address == address {
                    user_agreements.append(agreement);
                }
                i += 1;
            };
            user_agreements
        }

        fn validate_agreement(ref self: ContractState, agreementId: u256) {
            let agreement = self.agreements.entry(agreementId).read();
            let caller_address = get_caller_address();
            assert(caller_address == agreement.second_party_address, 'unauthorized caller');

            if caller_address == agreement.second_party_address {
                self.agreements.entry(agreementId).validate_signature.write(true);
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

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

