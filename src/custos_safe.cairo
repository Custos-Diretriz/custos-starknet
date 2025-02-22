#[starknet::contract]
pub mod CustosSafe {
    use crate::interfaces::ICrimeWitness;

    use starknet::{
        ContractAddress, get_caller_address, ClassHash,
        storage::{Map, StoragePointerWriteAccess, StoragePathEntry, MutableVecTrait, Vec, VecTrait}
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::ERC721HooksEmptyImpl;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        token_id: u256,
        token_uri: Map::<u256, ByteArray>,
        owners: Map::<u256, ContractAddress>,
        user_files: Map::<ContractAddress, Vec<ByteArray>>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        URI: URI,
    }

    #[derive(Drop, starknet::Event)]
    struct URI {
        #[key]
        id: u256,
        uri: ByteArray,
        msg: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self
            .erc721
            .initializer("CrimeRecords", "CRD", "QmbEgRoiC7SG9d6oY5uDpkKx8BikE3vMWYi6M75Kns68N6");
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl CrimeWitness of ICrimeWitness<ContractState> {
        fn crime_record(ref self: ContractState, uri: ByteArray, data: Span<felt252>) -> bool {
            let user = get_caller_address();
            let id_count = self.token_id.read() + 1;

            self.set_token_uri(id_count, uri);

            self.erc721.safe_mint(user, id_count, data);

            self.token_id.write(id_count);

            true
        }


        fn store_cid(ref self: ContractState, file_cid: ByteArray) {
            assert(file_cid.len() > 0, 'invalid cid');
            let caller = get_caller_address();
            let vec = self.user_files.entry(caller);
            vec.append().write(file_cid);
        }

        // caller can only access CIDs uploaded from his account/wallet
        fn get_cid(self: @ContractState, account: ContractAddress) -> Array<ByteArray> {
            let mut cid_arr = array![];
            let cid_count = self.user_files.entry(account).len();
            assert!(cid_count > 0, "no cid for user");
            for index in 0
                ..self
                    .user_files
                    .entry(account)
                    .len() {
                        cid_arr.append(self.user_files.entry(account).at(index).read());
                    };
            cid_arr
        }

        fn get_token_uri(self: @ContractState, id: u256) -> ByteArray {
            self.token_uri.entry(id).read()
        }

        fn get_all_user_uploads(self: @ContractState, user: ContractAddress) -> Array<u256> {
            let mut user_ids = ArrayTrait::new();
            let counter = self.token_id.read();
            let mut index: u256 = 1;

            while index < counter + 1 {
                let owner = self.erc721.owner_of(index);
                if owner == user {
                    user_ids.append(index)
                };
                index += 1;
            };
            user_ids
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn set_token_uri(ref self: ContractState, id: u256, uri: ByteArray) -> bool {
            self.token_uri.entry(id).write(uri);

            let uri = self.token_uri.entry(id).read();

            self.emit(URI { id, uri, msg: 'URI SET' });

            true
        }
    }
}
