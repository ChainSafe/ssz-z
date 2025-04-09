const std = @import("std");
const p = @import("./primitive.zig");
const ssz = @import("ssz");
const param = @import("./param.zig");
const getPreset = @import("./param.zig").getPreset;
const preset = getPreset();

// Misc types
// ==========
pub const AttestationSubnets = ssz.BitVectorType(param.ATTESTATION_SUBNET_COUNT);

/// BeaconBlockHeader where slot is bounded by the clock, and values above it are invalid
pub const BeaconBlockHeader = ssz.FixedContainerType(struct {
    slot: p.Slot,
    proposer_index: p.ValidatorIndex,
    parent_root: p.Root,
    state_root: p.Root,
    body_root: p.Root,
});

pub const SignedBeaconBlockHeader = ssz.FixedContainerType(struct {
    message: BeaconBlockHeader,
    signature: p.BLSSignature,
});

pub const Checkpoint = ssz.FixedContainerType(struct {
    epoch: p.Epoch,
    root: p.Root,
});

pub const CommitteeBits = ssz.BitListType(preset.MAX_VALIDATORS_PER_COMMITTEE);
pub const CommitteeIndices = ssz.FixedListType(p.ValidatorIndex, preset.MAX_VALIDATORS_PER_COMMITTEE);

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

pub const DepositDataRootFullList = ssz.FixedListType(p.Root, preset.VALIDATOR_REGISTRY_LIMIT);

pub const DepositEvent = ssz.FixedContainerType(struct {
    deposit_data: DepositData,
    block_number: p.Uint64,
    index: p.Uint64,
});

pub const Eth1Data = ssz.FixedContainerType(struct {
    deposit_root: p.Root,
    deposit_count: p.Uint64,
    block_hash: p.Bytes32,
});

pub const Eth1DataVotes = ssz.FixedListType(Eth1Data, preset.EPOCHS_PER_ETH1_VOTING_PERIOD);

pub const Eth1DataOrdered = ssz.FixedContainerType(struct {
    deposit_root: p.Root,
    deposit_count: p.Uint64,
    block_hash: p.Bytes32,
    block_number: p.Uint64,
});

// TODO DepositsDataSnapshot

/// Spec'ed but only used in lodestar as a type
pub const Eth1Block = ssz.FixedContainerType(struct {
    timestamp: p.Uint64,
    deposit_root: p.Root,
    deposit_count: p.Uint64,
});

pub const Fork = ssz.FixedContainerType(struct {
    previous_version: p.Version,
    current_version: p.Version,
    epoch: p.Epoch,
});

pub const ForkData = ssz.FixedContainerType(struct {
    current_version: p.Version,
    genesis_validators_root: p.Root,
});

pub const ENRForkID = ssz.FixedContainerType(struct {
    fork_digest: p.ForkDigest,
    next_fork_version: p.Version,
    next_fork_epoch: p.Epoch,
});

pub const HistoricalBlockRoots = ssz.FixedListType(p.Root, preset.HISTORICAL_ROOTS_LIMIT);

pub const HistoricalStateRoots = ssz.FixedListType(p.Root, preset.HISTORICAL_ROOTS_LIMIT);

pub const HistoricalBatch = ssz.VariableContainerType(struct {
    block_roots: HistoricalBlockRoots,
    state_roots: HistoricalStateRoots,
});

pub const HistoricalBatchRoots = ssz.VariableContainerType(struct {
    block_roots: HistoricalBlockRoots,
    state_roots: HistoricalStateRoots,
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

pub const Validators = ssz.FixedListType(Validator, preset.VALIDATOR_REGISTRY_LIMIT);

pub const Balances = ssz.FixedListType(p.Gwei, preset.VALIDATOR_REGISTRY_LIMIT);

pub const RandaoMixes = ssz.FixedVectorType(p.Bytes32, preset.EPOCHS_PER_HISTORICAL_VECTOR);

pub const Slashings = ssz.FixedVectorType(p.Gwei, preset.EPOCHS_PER_SLASHINGS_VECTOR);

pub const JustificationBits = ssz.BitVectorType(param.JUSTIFICATION_BITS_LENGTH);

pub const AttestationData = ssz.FixedContainerType(struct {
    slot: p.Slot,
    index: p.CommitteeIndex,
    beacon_block_root: p.Root,
    source: Checkpoint,
    target: Checkpoint,
});

pub const IndexedAttestation = ssz.VariableContainerType(struct {
    attesting_indices: CommitteeIndices,
    data: AttestationData,
    signature: p.BLSSignature,
});

pub const PendingAttestation = ssz.VariableContainerType(struct {
    aggregation_bits: CommitteeBits,
    data: AttestationData,
    inclusion_delay: p.Uint64,
    proposer_index: p.ValidatorIndex,
});

pub const SigningData = ssz.FixedContainerType(struct {
    object_root: p.Root,
    domain: p.Domain,
});

pub const Attestation = ssz.VariableContainerType(struct {
    aggregation_bits: CommitteeBits,
    data: AttestationData,
    signature: p.BLSSignature,
});

pub const AttesterSlashing = ssz.VariableContainerType(struct {
    attestation_1: IndexedAttestation,
    attestation_2: IndexedAttestation,
});

pub const DepositProof = ssz.FixedVectorType(p.Bytes32, param.DEPOSIT_CONTRACT_TREE_DEPTH);
pub const Deposit = ssz.FixedContainerType(struct {
    proof: DepositProof,
    data: DepositData,
});

pub const ProposerSlashing = ssz.FixedContainerType(struct {
    signed_header_1: SignedBeaconBlockHeader,
    signed_header_2: SignedBeaconBlockHeader,
});

pub const VoluntaryExit = ssz.FixedContainerType(struct {
    epoch: p.Epoch,
    validator_index: p.ValidatorIndex,
});

pub const SignedVoluntaryExit = ssz.FixedContainerType(struct {
    message: VoluntaryExit,
    signature: p.BLSSignature,
});

pub const ProposerSlashings = ssz.FixedListType(ProposerSlashing, preset.MAX_PROPOSER_SLASHINGS);
pub const AttesterSlashings = ssz.VariableListType(AttesterSlashing, preset.MAX_ATTESTER_SLASHINGS);
pub const Attestations = ssz.VariableListType(Attestation, preset.MAX_ATTESTATIONS);
pub const Deposits = ssz.FixedListType(Deposit, preset.MAX_DEPOSITS);
pub const SignedVoluntaryExits = ssz.FixedListType(SignedVoluntaryExit, preset.MAX_VOLUNTARY_EXITS);

pub const BeaconBlockBody = ssz.VariableContainerType(struct {
    randao_reveal: p.BLSSignature,
    eth1_data: Eth1Data,
    graffiti: p.Bytes32,
    proposer_slashings: ProposerSlashings,
    attester_slashings: AttesterSlashings,
    attestations: Attestations,
    deposits: Deposits,
    voluntary_exits: SignedVoluntaryExits,
});

pub const BeaconBlock = ssz.VariableContainerType(struct {
    slot: p.Slot,
    proposer_index: p.ValidatorIndex,
    parent_root: p.Root,
    state_root: p.Root,
    body: BeaconBlockBody,
});

pub const SignedBeaconBlock = ssz.VariableContainerType(struct {
    message: BeaconBlock,
    signature: p.BLSSignature,
});

// State types
// ===========

pub const EpochAttestations = ssz.VariableListType(PendingAttestation, 0xDEADBEEF);

pub const BeaconState = ssz.VariableContainerType(struct {
    slot: p.Slot,
    genesis_time: p.Uint64,
    genesis_validators_root: p.Root,
    fork: Fork,
    latest_block_header: BeaconBlockHeader,
    block_roots: HistoricalBlockRoots,
    state_roots: HistoricalStateRoots,
    historical_roots: HistoricalBatchRoots,
    eth1_data: Eth1Data,
    eth1_data_votes: Eth1DataVotes,
    eth1_deposit_index: p.Uint64,
    validators: Validators,
    balances: Balances,
    randao_mixes: RandaoMixes,
    slashings: Slashings,
    previous_epoch_attestations: EpochAttestations,
    current_epoch_attestations: EpochAttestations,
    justification_bits: JustificationBits,
    previous_justified_checkpoint: Checkpoint,
    current_justified_checkpoint: Checkpoint,
    finalized_checkpoint: Checkpoint,
});

// Validator types
// ===============

pub const CommitteeAssignment = ssz.VariableContainerType(struct {
    validators: CommitteeIndices,
    committee_index: p.CommitteeIndex,
    slot: p.Slot,
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

// ReqResp types
// =============

pub const Status = ssz.FixedContainerType(struct {
    fork_digest: p.ForkDigest,
    finalized_root: p.Root,
    finalized_epoch: p.Epoch,
    head_root: p.Root,
    head_slot: p.Slot,
});

pub const Goodbye = p.Uint64;

pub const Ping = p.Uint64;

pub const Metadata = ssz.FixedContainerType(struct {
    seq_number: p.Uint64,
    attnets: AttestationSubnets,
});

pub const BeaconBlocksByRangeRequest = ssz.FixedContainerType(struct {
    start_slot: p.Slot,
    count: p.Uint64,
    step: p.Uint64,
});

pub const BeaconBlocksByRootRequest = ssz.FixedListType(p.Root, 0xDEADBEEF);

// Api types
// =========

pub const Genesis = ssz.FixedContainerType(struct {
    genesis_time: p.Uint64,
    genesis_validators_root: p.Root,
    genesis_fork_version: p.Version,
});

// TODO: add more tests
test "auto generated types" {
    // expected data structure
    const ECheckpoint = struct {
        epoch: u64,
        root: [32]u8,
    };
    try expectTypesEqual(ECheckpoint, Checkpoint.Type);

    // expected data structure
    const EAttestationData = struct {
        slot: u64,
        index: u64,
        beacon_block_root: [32]u8,
        source: ECheckpoint,
        target: ECheckpoint,
    };
    try expectTypesEqual(EAttestationData, AttestationData.Type);
}

fn expectTypesEqual(a: type, b: type) !void {
    try std.testing.expectEqual(@alignOf(a), @alignOf(b));
    try std.testing.expectEqual(@sizeOf(a), @sizeOf(b));
}

test {}
