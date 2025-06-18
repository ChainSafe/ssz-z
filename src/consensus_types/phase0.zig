const std = @import("std");
const ssz = @import("ssz");
const p = @import("primitive.zig");
const c = @import("constants.zig");
const preset = @import("preset.zig").active_preset;

pub const Fork = ssz.FixedContainerType(struct {
    previous_version: p.Version,
    current_version: p.Version,
    epoch: p.Epoch,
});

pub const ForkData = ssz.FixedContainerType(struct {
    current_version: p.Version,
    genesis_validators_root: p.Root,
});

pub const Checkpoint = ssz.FixedContainerType(struct {
    epoch: p.Epoch,
    root: p.Root,
});

pub const Validator = ssz.FixedContainerType(struct {
    pubkey: p.BLSPubkey,
    withdrawal_credentials: p.Root,
    effective_balance: p.Gwei,
    slashed: p.Boolean,
    activation_eligibility_epoch: p.Epoch,
    activation_epoch: p.Epoch,
    exit_epoch: p.Epoch,
    withdrawable_epoch: p.Epoch,
});

pub const AttestationData = ssz.FixedContainerType(struct {
    slot: p.Slot,
    index: p.CommitteeIndex,
    beacon_block_root: p.Root,
    source: Checkpoint,
    target: Checkpoint,
});

pub const IndexedAttestation = ssz.VariableContainerType(struct {
    attesting_indices: ssz.FixedListType(p.ValidatorIndex, preset.MAX_VALIDATORS_PER_COMMITTEE),
    data: AttestationData,
    signature: p.BLSSignature,
});

pub const PendingAttestation = ssz.VariableContainerType(struct {
    aggregation_bits: ssz.BitListType(preset.MAX_VALIDATORS_PER_COMMITTEE),
    data: AttestationData,
    inclusion_delay: p.Uint64,
    proposer_index: p.ValidatorIndex,
});

pub const Eth1Data = ssz.FixedContainerType(struct {
    deposit_root: p.Root,
    deposit_count: p.Uint64,
    block_hash: p.Bytes32,
});

pub const Eth1DataVotes = ssz.FixedListType(Eth1Data, preset.EPOCHS_PER_ETH1_VOTING_PERIOD * preset.SLOTS_PER_EPOCH);

pub const JustificationBits = ssz.BitVectorType(c.JUSTIFICATION_BITS_LENGTH);

pub const HistoricalBatch = ssz.FixedContainerType(struct {
    block_roots: ssz.FixedVectorType(p.Root, preset.SLOTS_PER_HISTORICAL_ROOT),
    state_roots: ssz.FixedVectorType(p.Root, preset.SLOTS_PER_HISTORICAL_ROOT),
});

pub const DepositMessage = ssz.FixedContainerType(struct {
    pubkey: p.BLSPubkey,
    withdrawal_credentials: p.Root,
    amount: p.Uint64,
});

pub const DepositData = ssz.FixedContainerType(struct {
    pubkey: p.BLSPubkey,
    withdrawal_credentials: p.Bytes32,
    amount: p.Uint64,
    signature: p.BLSSignature,
});

pub const BeaconBlockHeader = ssz.FixedContainerType(struct {
    slot: p.Slot,
    proposer_index: p.ValidatorIndex,
    parent_root: p.Root,
    state_root: p.Root,
    body_root: p.Root,
});

pub const SigningData = ssz.FixedContainerType(struct {
    object_root: p.Root,
    domain: p.Domain,
});

pub const ProposerSlashing = ssz.FixedContainerType(struct {
    signed_header_1: SignedBeaconBlockHeader,
    signed_header_2: SignedBeaconBlockHeader,
});

pub const AttesterSlashing = ssz.VariableContainerType(struct {
    attestation_1: IndexedAttestation,
    attestation_2: IndexedAttestation,
});

pub const Attestation = ssz.VariableContainerType(struct {
    aggregation_bits: ssz.BitListType(preset.MAX_VALIDATORS_PER_COMMITTEE),
    data: AttestationData,
    signature: p.BLSSignature,
});

pub const Deposit = ssz.FixedContainerType(struct {
    proof: ssz.FixedVectorType(p.Bytes32, c.DEPOSIT_CONTRACT_TREE_DEPTH + 1),
    data: DepositData,
});

pub const VoluntaryExit = ssz.FixedContainerType(struct {
    epoch: p.Epoch,
    validator_index: p.ValidatorIndex,
});

pub const BeaconBlockBody = ssz.VariableContainerType(struct {
    randao_reveal: p.BLSSignature,
    eth1_data: Eth1Data,
    graffiti: p.Bytes32,
    proposer_slashings: ssz.FixedListType(ProposerSlashing, preset.MAX_PROPOSER_SLASHINGS),
    attester_slashings: ssz.VariableListType(AttesterSlashing, preset.MAX_ATTESTER_SLASHINGS),
    attestations: ssz.VariableListType(Attestation, preset.MAX_ATTESTATIONS),
    deposits: ssz.FixedListType(Deposit, preset.MAX_DEPOSITS),
    voluntary_exits: ssz.FixedListType(SignedVoluntaryExit, preset.MAX_VOLUNTARY_EXITS),
});

pub const BeaconBlock = ssz.VariableContainerType(struct {
    slot: p.Slot,
    proposer_index: p.ValidatorIndex,
    parent_root: p.Root,
    state_root: p.Root,
    body: BeaconBlockBody,
});

pub const SignedBeaconBlockHeader = ssz.FixedContainerType(struct {
    message: BeaconBlockHeader,
    signature: p.BLSSignature,
});

pub const BeaconState = ssz.VariableContainerType(struct {
    genesis_time: p.Uint64,
    genesis_validators_root: p.Root,
    slot: p.Slot,
    fork: Fork,
    latest_block_header: BeaconBlockHeader,
    block_roots: ssz.FixedVectorType(p.Root, preset.SLOTS_PER_HISTORICAL_ROOT),
    state_roots: ssz.FixedVectorType(p.Root, preset.SLOTS_PER_HISTORICAL_ROOT),
    historical_roots: ssz.FixedListType(p.Root, preset.HISTORICAL_ROOTS_LIMIT),
    eth1_data: Eth1Data,
    eth1_data_votes: Eth1DataVotes,
    eth1_deposit_index: p.Uint64,
    validators: ssz.FixedListType(Validator, preset.VALIDATOR_REGISTRY_LIMIT),
    balances: ssz.FixedListType(p.Gwei, preset.VALIDATOR_REGISTRY_LIMIT),
    randao_mixes: ssz.FixedVectorType(p.Bytes32, preset.EPOCHS_PER_HISTORICAL_VECTOR),
    slashings: ssz.FixedVectorType(p.Gwei, preset.EPOCHS_PER_SLASHINGS_VECTOR),
    previous_epoch_attestations: ssz.VariableListType(PendingAttestation, preset.MAX_ATTESTATIONS * preset.SLOTS_PER_EPOCH),
    current_epoch_attestations: ssz.VariableListType(PendingAttestation, preset.MAX_ATTESTATIONS * preset.SLOTS_PER_EPOCH),
    justification_bits: JustificationBits,
    previous_justified_checkpoint: Checkpoint,
    current_justified_checkpoint: Checkpoint,
    finalized_checkpoint: Checkpoint,
});

pub const SignedVoluntaryExit = ssz.FixedContainerType(struct {
    message: VoluntaryExit,
    signature: p.BLSSignature,
});

pub const SignedBeaconBlock = ssz.VariableContainerType(struct {
    message: BeaconBlock,
    signature: p.BLSSignature,
});

// Validator types
// ===============

pub const Eth1Block = ssz.FixedContainerType(struct {
    timestamp: p.Uint64,
    deposit_root: p.Root,
    deposit_count: p.Uint64,
});

pub const AggregateAndProof = ssz.VariableContainerType(struct {
    aggregator_index: p.ValidatorIndex,
    aggregate: Attestation,
    selection_proof: p.BLSSignature,
});

pub const SignedAggregateAndProof = ssz.VariableContainerType(struct {
    message: AggregateAndProof,
    signature: p.BLSSignature,
});
