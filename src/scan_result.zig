const root = @import("root.zig");
const Allocator = root.Allocator;
const c = root.c;

pub const ScanToken = struct {
    start: c_int,
    end: c_int,
    token: c_int,
    keyword_kind: c_int,
};

pub const ScanResult = struct {
    allocator: Allocator,
    tokens: []ScanToken,
    stderr_buffer: ?[]u8,

    pub fn deinit(self: *ScanResult) void {
        self.allocator.free(self.tokens);
        if (self.stderr_buffer) |stderr| self.allocator.free(stderr);
        self.* = undefined;
    }
};

pub fn fromUnpacked(
    allocator: Allocator,
    protobuf: *const c.PgQuery__ScanResult,
    stderr_buffer: ?[]const u8,
) Allocator.Error!ScanResult {
    const tokens = try allocator.alloc(ScanToken, protobuf.n_tokens);
    errdefer allocator.free(tokens);

    for (tokens, 0..) |*token, index| {
        const source = protobuf.tokens[index].?;
        token.* = .{
            .start = source[0].start,
            .end = source[0].end,
            .token = @intCast(source[0].token),
            .keyword_kind = @intCast(source[0].keyword_kind),
        };
    }

    return .{
        .allocator = allocator,
        .tokens = tokens,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
    };
}

pub fn fromGenerated(
    allocator: Allocator,
    protobuf: *const root.pb.ScanResult,
    stderr_buffer: ?[]const u8,
) Allocator.Error!ScanResult {
    const tokens = try allocator.alloc(ScanToken, protobuf.tokens.items.len);
    errdefer allocator.free(tokens);

    for (tokens, protobuf.tokens.items) |*token, source| {
        token.* = .{
            .start = @intCast(source.start),
            .end = @intCast(source.end),
            .token = @intFromEnum(source.token),
            .keyword_kind = @intFromEnum(source.keyword_kind),
        };
    }

    return .{
        .allocator = allocator,
        .tokens = tokens,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
    };
}
