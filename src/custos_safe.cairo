#[starknet::contract]
pub mod CustosSafe {
    use crate::interfaces::ICustosSafe;

    use starknet::{
        ContractAddress, get_caller_address, ClassHash, contract_address_const,
        storage::{
            Map, StorageMapWriteAccess, StorageMapReadAccess, StoragePointerReadAccess,
            StoragePointerWriteAccess, StoragePathEntry, MutableVecTrait, Vec, VecTrait
        }
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::ERC721HooksEmptyImpl;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use alexandria_storage::list::{List, ListTrait, IndexView};

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
        group: Map::<ContractAddress, Map<u256, Vec<ByteArray>>>,
        // group_list: Map::<ContractAddress, Map<u256, List<ByteArray>>>,
        id_to_group: Map::<u256, Group>,
    }

    #[derive(Drop, starknet::Store)]
    struct Group {
        id: u256,
        title: ByteArray,
        owner: ContractAddress,
        is_deleted: bool
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
    impl CustosSafeImpl of ICustosSafe<ContractState> {
        fn upload_cid(ref self: ContractState, file_cid: ByteArray) {
            assert(file_cid.len() > 0, 'invalid cid');
            let caller = get_caller_address();
            let vec = self.user_files.entry(caller);
            vec.append().write(file_cid);
        }

        fn batch_upload_cid(ref self: ContractState, cids: Array<ByteArray>) {
            assert(cids.len() > 0, 'invalid cid array');
            let caller = get_caller_address();

            let mut i: usize = 0;
            loop {
                if i >= cids.len() {
                    break;
                }
                self.user_files.entry(caller).append().write(cids.at(i).clone());

                i += 1;
            }
        }


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

        /// @dev Use uuid for group_id
        fn create_group(ref self: ContractState, group_title: ByteArray, group_id: u256) -> u256 {
            let caller = get_caller_address();
            assert(group_id > 0, 'invalid id');
            let group = Group {
                id: group_id, title: group_title, owner: caller, is_deleted: false
            };
            self.id_to_group.entry(group_id).write(group);
            group_id
        }

        fn delete_group(ref self: ContractState, group_id: u256) {
            let caller = get_caller_address();
            let mut group = self.id_to_group.entry(group_id).read();

            assert(caller == group.owner, 'unauthorized caller');
            group =
                Group {
                    id: 0, title: "", owner: contract_address_const::<'0'>(), is_deleted: true
                };

            self.id_to_group.entry(group_id).write(group);
        }

        /// @notice To add file to a group
        fn add_to_group(ref self: ContractState, group_id: u256, cid: ByteArray) -> u64 {
            let caller = get_caller_address();
            let group: Group = self.id_to_group.entry(group_id).read();
            assert(group.is_deleted == false, 'inactive group');
            assert(cid.len() > 0, 'invalid cid');
            self.group.entry(caller).entry(group_id).append().write(cid);

            let stored_cids = self.group.entry(caller).entry(group_id);
            assert(stored_cids.len() > 0, 'cid not stored');
            stored_cids.len()
        }

        fn remove_from_group(ref self: ContractState, group_id: u256, cid: ByteArray) -> ByteArray {
            let caller = get_caller_address();
            let group: Group = self.id_to_group.entry(group_id).read();
            assert(group.is_deleted == false, 'inactive group');

            let mut list = self.group.entry(caller).entry(group_id);
            let cid_count = list.len();
            assert(cid_count > 0, 'no cid in group');

            let mut i = 0;
            let mut index_of_cid = 0;
            let mut found = false;
            loop {
                if i >= cid_count {
                    break;
                }

                let stored_cid = list.at(i).read();
                if stored_cid == cid {
                    found = true;
                    index_of_cid = i;
                    break;
                }

                i += 1;
            };

            assert(found, 'cid not found');
            let cid_at_index = list.at(index_of_cid);
            cid_at_index.write("");
            assert(cid_at_index.read() == "", 'cid not removed');
            cid_at_index.read()
        }


        fn get_group(self: @ContractState, group_id: u256) -> Array<ByteArray> {
            let group: Group = self.id_to_group.entry(group_id).read();
            assert(group.is_deleted == false, 'inactive group');

            let mut group_arr = ArrayTrait::new();
            let group_vec = self.group.entry(group.owner).entry(group_id);
            let group_count = group_vec.len();

            assert!(group_count > 0, "No CIDs found for this group");

            for index in 0
                ..group_count {
                    let cid = group_vec.at(index).read();
                    if cid.len() > 0 {
                        group_arr.append(cid);
                    };
                };
            group_arr
        }
    }
}
