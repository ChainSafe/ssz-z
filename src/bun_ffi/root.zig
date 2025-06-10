const consensus_types = @import("consensus_types");

const phase0_type_names = [_][]const u8{
    "Checkpoint",
    "Attestation",
    "AttestationData",
    "BeaconBlockHeader",
    "BeaconBlock",
    "SignedBeaconBlock",
    "SignedAggregateAndProof",
    "SyncCommittee",
    "SyncCommitteeMessage",
    "SyncCommitteeContribution",
    "SignedVoluntaryExit",
    "ProposerSlashing",
    "AttesterSlashing",
};

export fn compute_type_id(fork: u8, type_id: u16) u32 {
    return @as(u32, (fork << 16) | type_id);
}

export fn get_type_kind(type_id: u32) u8 {
    const fork = @as(u8, type_id >> 16);
    return @intFromEnum(consensus_types.phase0.kind);
}

export fn allocate(type_id: u32) u32 {}

export fn free(ptr: u32) void {}

export fn hash_tree_root(type_id: u32, ptr: u32) [32]u8 {
}

export fn phase0_checkpoint_kind() u8 {
    return @intFromEnum(consensus_types.phase0.Checkpoint.kind);
}

export fn phase0_checkpoint_fixed_size() u8 {
    return consensus_types.phase0.Checkpoint.fixed_size;
}

export fn phase0_checkpoint_field_offsets() []const usize {
    return consensus_types.phase0.Checkpoint.field_offsets;
}

export 