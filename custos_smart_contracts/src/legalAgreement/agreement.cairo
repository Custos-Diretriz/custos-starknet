use starknet::core::types::{Address, felt256};
use starknet::core::utils::{get_selector_from_name, CairoContract};

#[derive(Copy, Clone, Debug, Default, PartialEq, Eq)]
struct LegalAgreement {
    creator: Address,
    content: Felt256,
    second_party_address: Address,
    first_party: DictAccess<Address, Participants>,
    second_party: DictAccess<Address, Participants>,
    signed: bool,
    validate_signature: bool,
}

#[derive(Copy, Clone, Debug, Default, PartialEq, Eq)]
struct Participants {
    name: felt256,
    valid_id: felt256,
}



#[storage_var]
fn agreement_count() -> felt256 {}

#[event]
fn AgreementCreated(agreement_id: felt256, creator: Address, content: felt256) {}

#[event]
fn AgreementSigned(agreement_id: felt256, signer: Address) {}

#[event]
fn AgreementValid(agreement_id: felt256, first_party_id: felt256, second_party_id: felt256) {}

fn only_creators(id: felt256, sender: Address) -> Result<T> {
    let creator = agreements().get(id).unwrap().creator;
    if creator != sender {
        return Err("Only the creator can perform this action.");
    }
    Ok(())
}

#[external]
fn create_agreement(content: felt256, second_party_address: Address, first_party_name: felt256, first_party_valid_id: felt256) -> Result<felt256> {
    let current_count = agreement_count().get().unwrap_or_default();
    agreement_count().set(current_count + 1);

    let agreement = LegalAgreement {
        creator: get_caller_address(),
        content: content,
        second_party_address,
        first_party: DictAccess::new(),
        second_party: DictAccess::new(),
        signed: false,
        validate_signature: false,
    };

    let first_party_participant = Participants {
        name: first_party_name,
        valid_id: first_party_valid_id,
    };
    agreement.first_party.set(get_caller_address(), first_party_participant);

    agreements().set(current_count + 1, agreement);

    AgreementCreated::emit(current_count + 1, get_caller_address(), hash160(concat(content)));

    Ok(current_count + 1)
}

#[external]
fn sign_agreement(agreement_id: felt256, fullname: felt256, valid_id: felt256) -> Result<T> {
    let agreement = agreements().get(agreement_id).ok_or("Agreement not found")?;
    if agreement.second_party_address != get_caller_address() {
        return Err("Only the second party can sign the agreement.");
    }
    if agreement.signed {
        return Err("Agreement already signed.");
    }

    let mut updated_agreement = agreement;
    updated_agreement.signed = true;
    let second_party_participant = Participants {
        name: fullname,
        valid_id,
    };
    updated_agreement.second_party.set(get_caller_address(), second_party_participant);

    agreements().set(agreement_id, updated_agreement);

    AgreementSigned::emit(agreement_id, get_caller_address());

    Ok(())
}

#[external]
fn validate_signature(agreement_id: felt256) -> Result<T> {
    let mut agreement = agreements().get(agreement_id).ok_or("Agreement not found")?;
    if !agreement.signed {
        return Err("Agreement not signed by both parties.");
    }

    agreement.validate_signature = true;
    agreements().set(agreement_id, agreement);

    AgreementValid::emit(
        agreement_id,
        agreement.first_party.get(agreement.creator).ok_or("First party not found")?.valid_id,
        agreement.second_party.get(agreement.second_party_address).ok_or("Second party not found")?.valid_id,
    );

    Ok(())
}
