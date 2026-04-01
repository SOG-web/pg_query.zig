const ops = @import("../ops.zig");
const root = @import("../root.zig");
pub const RawParseResult = root.RawParseResult;
pub const RawScanResult = root.RawScanResult;
pub const Fingerprint = root.Fingerprint;
pub const OwnedString = root.OwnedString;
pub const Outcome = root.Outcome;

pub fn parse(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(RawParseResult) {
    return ops.parseRaw(allocator, sql);
}

pub fn scan(allocator: root.Allocator, sql: []const u8) root.ApiError!Outcome(RawScanResult) {
    return ops.scanRaw(allocator, sql);
}

pub fn deparse(allocator: root.Allocator, raw: *const RawParseResult) root.ApiError!Outcome(OwnedString) {
    return ops.deparseRaw(allocator, raw);
}

pub fn fingerprint(allocator: root.Allocator, raw: *const RawParseResult) root.ApiError!Outcome(Fingerprint) {
    return ops.fingerprintRaw(allocator, raw);
}
