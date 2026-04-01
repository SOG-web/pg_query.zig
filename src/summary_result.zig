const std = @import("std");

const root = @import("root.zig");
const Allocator = root.Allocator;
const Context = root.Context;
const c = root.c;

pub const Table = struct {
    name: []u8,
    schema_name: []u8,
    table_name: []u8,
    context: Context,
};

pub const Function = struct {
    name: []u8,
    function_name: []u8,
    schema_name: ?[]u8,
    context: Context,
};

pub const FilterColumn = struct {
    schema_name: ?[]u8,
    table_name: ?[]u8,
    column: []u8,
};

pub const SummaryResult = struct {
    allocator: Allocator,
    stderr_buffer: ?[]u8,
    warnings: []const []const u8,
    tables_info: []Table,
    aliases: std.StringHashMap([]u8),
    cte_names: [][]u8,
    functions_info: []Function,
    filter_columns: []FilterColumn,
    truncated_query: []u8,
    statement_types: [][]u8,

    pub fn deinit(self: *SummaryResult) void {
        self.allocator.free(self.warnings);
        if (self.stderr_buffer) |stderr_buffer| self.allocator.free(stderr_buffer);

        for (self.tables_info) |table| {
            self.allocator.free(table.name);
            self.allocator.free(table.schema_name);
            self.allocator.free(table.table_name);
        }
        self.allocator.free(self.tables_info);

        var alias_iter = self.aliases.iterator();
        while (alias_iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.aliases.deinit();

        for (self.cte_names) |name| self.allocator.free(name);
        self.allocator.free(self.cte_names);

        for (self.functions_info) |function| {
            self.allocator.free(function.name);
            self.allocator.free(function.function_name);
            if (function.schema_name) |schema_name| self.allocator.free(schema_name);
        }
        self.allocator.free(self.functions_info);

        for (self.filter_columns) |column| {
            if (column.schema_name) |schema_name| self.allocator.free(schema_name);
            if (column.table_name) |table_name| self.allocator.free(table_name);
            self.allocator.free(column.column);
        }
        self.allocator.free(self.filter_columns);

        self.allocator.free(self.truncated_query);
        for (self.statement_types) |statement_type| self.allocator.free(statement_type);
        self.allocator.free(self.statement_types);

        self.* = undefined;
    }

    pub fn tables(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return uniqueStringsFromTables(allocator, self.tables_info);
    }

    pub fn selectTables(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return filterTableNamesByContext(allocator, self.tables_info, .select);
    }

    pub fn dmlTables(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return filterTableNamesByContext(allocator, self.tables_info, .dml);
    }

    pub fn ddlTables(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return filterTableNamesByContext(allocator, self.tables_info, .ddl);
    }

    pub fn functions(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return uniqueStringsFromFunctions(allocator, self.functions_info);
    }

    pub fn ddlFunctions(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return filterFunctionNamesByContext(allocator, self.functions_info, .ddl);
    }

    pub fn callFunctions(self: *const SummaryResult, allocator: Allocator) Allocator.Error![][]const u8 {
        return filterFunctionNamesByContext(allocator, self.functions_info, .call);
    }

    pub fn aliasesMap(self: *const SummaryResult) *const std.StringHashMap([]u8) {
        return &self.aliases;
    }

    pub fn cteNames(self: *const SummaryResult) []const []u8 {
        return self.cte_names;
    }

    pub fn filterColumns(self: *const SummaryResult) []const FilterColumn {
        return self.filter_columns;
    }

    pub fn statementTypes(self: *const SummaryResult) []const []u8 {
        return self.statement_types;
    }
};

pub fn fromUnpacked(
    allocator: Allocator,
    protobuf: *const c.PgQuery__SummaryResult,
    stderr_buffer: ?[]const u8,
) Allocator.Error!SummaryResult {
    var result: SummaryResult = .{
        .allocator = allocator,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
        .warnings = undefined,
        .tables_info = try copyTables(allocator, protobuf),
        .aliases = try copyAliases(allocator, protobuf),
        .cte_names = try copyCStringArray(allocator, protobuf.n_cte_names, protobuf.cte_names),
        .functions_info = try copyFunctions(allocator, protobuf),
        .filter_columns = try copyFilterColumns(allocator, protobuf),
        .truncated_query = try dupCString(allocator, protobuf.truncated_query),
        .statement_types = try copyCStringArray(allocator, protobuf.n_statement_types, protobuf.statement_types),
    };
    errdefer result.deinit();
    result.warnings = try parseWarnings(allocator, result.stderr_buffer);
    return result;
}

pub fn fromGenerated(
    allocator: Allocator,
    protobuf: *const root.pb.SummaryResult,
    stderr_buffer: ?[]const u8,
) Allocator.Error!SummaryResult {
    var result: SummaryResult = .{
        .allocator = allocator,
        .stderr_buffer = if (stderr_buffer) |stderr| try allocator.dupe(u8, stderr) else null,
        .warnings = undefined,
        .tables_info = try copyGeneratedTables(allocator, protobuf),
        .aliases = try copyGeneratedAliases(allocator, protobuf),
        .cte_names = try copyGeneratedStringArray(allocator, protobuf.cte_names.items),
        .functions_info = try copyGeneratedFunctions(allocator, protobuf),
        .filter_columns = try copyGeneratedFilterColumns(allocator, protobuf),
        .truncated_query = try allocator.dupe(u8, protobuf.truncated_query),
        .statement_types = try copyGeneratedStringArray(allocator, protobuf.statement_types.items),
    };
    errdefer result.deinit();
    result.warnings = try parseWarnings(allocator, result.stderr_buffer);
    return result;
}

fn parseWarnings(allocator: Allocator, stderr_buffer: ?[]const u8) Allocator.Error![]const []const u8 {
    const stderr = stderr_buffer orelse return allocator.alloc([]const u8, 0);
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, stderr, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.startsWith(u8, trimmed, "WARNING")) count += 1;
    }

    const warnings = try allocator.alloc([]const u8, count);
    it = std.mem.splitScalar(u8, stderr, '\n');
    var index: usize = 0;
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (!std.mem.startsWith(u8, trimmed, "WARNING")) continue;
        warnings[index] = trimmed;
        index += 1;
    }
    return warnings;
}

fn copyTables(allocator: Allocator, protobuf: *const c.PgQuery__SummaryResult) Allocator.Error![]Table {
    const tables = try allocator.alloc(Table, protobuf.n_tables);
    errdefer allocator.free(tables);

    for (tables, 0..) |*table, index| {
        const source = protobuf.tables[index].?;
        table.* = .{
            .name = try dupCString(allocator, source[0].name),
            .schema_name = try dupCString(allocator, source[0].schema_name),
            .table_name = try dupCString(allocator, source[0].table_name),
            .context = contextFromSummary(source[0].context),
        };
    }

    return tables;
}

fn copyGeneratedTables(allocator: Allocator, protobuf: *const root.pb.SummaryResult) Allocator.Error![]Table {
    const tables = try allocator.alloc(Table, protobuf.tables.items.len);
    errdefer allocator.free(tables);

    for (tables, protobuf.tables.items) |*table, source| {
        table.* = .{
            .name = try allocator.dupe(u8, source.name),
            .schema_name = try allocator.dupe(u8, source.schema_name),
            .table_name = try allocator.dupe(u8, source.table_name),
            .context = contextFromGenerated(source.context),
        };
    }

    return tables;
}

fn copyAliases(
    allocator: Allocator,
    protobuf: *const c.PgQuery__SummaryResult,
) Allocator.Error!std.StringHashMap([]u8) {
    var aliases = std.StringHashMap([]u8).init(allocator);
    errdefer {
        var iter = aliases.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        aliases.deinit();
    }

    for (0..protobuf.n_aliases) |index| {
        const source = protobuf.aliases[index].?;
        const key = try dupCString(allocator, source[0].key);
        errdefer allocator.free(key);
        const value = try dupCString(allocator, source[0].value);
        errdefer allocator.free(value);
        try aliases.put(key, value);
    }

    return aliases;
}

fn copyGeneratedAliases(
    allocator: Allocator,
    protobuf: *const root.pb.SummaryResult,
) Allocator.Error!std.StringHashMap([]u8) {
    var aliases = std.StringHashMap([]u8).init(allocator);
    errdefer {
        var iter = aliases.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        aliases.deinit();
    }

    for (protobuf.aliases.items) |source| {
        const key = try allocator.dupe(u8, source.key);
        errdefer allocator.free(key);
        const value = try allocator.dupe(u8, source.value);
        errdefer allocator.free(value);
        try aliases.put(key, value);
    }

    return aliases;
}

fn copyFunctions(allocator: Allocator, protobuf: *const c.PgQuery__SummaryResult) Allocator.Error![]Function {
    const functions = try allocator.alloc(Function, protobuf.n_functions);
    errdefer allocator.free(functions);

    for (functions, 0..) |*function, index| {
        const source = protobuf.functions[index].?;
        const schema_name = try dupOptionalCString(allocator, source[0].schema_name);
        function.* = .{
            .name = try dupCString(allocator, source[0].name),
            .function_name = try dupCString(allocator, source[0].function_name),
            .schema_name = schema_name,
            .context = contextFromSummary(source[0].context),
        };
    }

    return functions;
}

fn copyGeneratedFunctions(allocator: Allocator, protobuf: *const root.pb.SummaryResult) Allocator.Error![]Function {
    const functions = try allocator.alloc(Function, protobuf.functions.items.len);
    errdefer allocator.free(functions);

    for (functions, protobuf.functions.items) |*function, source| {
        function.* = .{
            .name = try allocator.dupe(u8, source.name),
            .function_name = try allocator.dupe(u8, source.function_name),
            .schema_name = if (source.schema_name.len == 0) null else try allocator.dupe(u8, source.schema_name),
            .context = contextFromGenerated(source.context),
        };
    }

    return functions;
}

fn copyFilterColumns(allocator: Allocator, protobuf: *const c.PgQuery__SummaryResult) Allocator.Error![]FilterColumn {
    const filter_columns = try allocator.alloc(FilterColumn, protobuf.n_filter_columns);
    errdefer allocator.free(filter_columns);

    for (filter_columns, 0..) |*filter_column, index| {
        const source = protobuf.filter_columns[index].?;
        filter_column.* = .{
            .schema_name = try dupOptionalCString(allocator, source[0].schema_name),
            .table_name = try dupOptionalCString(allocator, source[0].table_name),
            .column = try dupCString(allocator, source[0].column),
        };
    }

    return filter_columns;
}

fn copyGeneratedFilterColumns(allocator: Allocator, protobuf: *const root.pb.SummaryResult) Allocator.Error![]FilterColumn {
    const filter_columns = try allocator.alloc(FilterColumn, protobuf.filter_columns.items.len);
    errdefer allocator.free(filter_columns);

    for (filter_columns, protobuf.filter_columns.items) |*filter_column, source| {
        filter_column.* = .{
            .schema_name = if (source.schema_name.len == 0) null else try allocator.dupe(u8, source.schema_name),
            .table_name = if (source.table_name.len == 0) null else try allocator.dupe(u8, source.table_name),
            .column = try allocator.dupe(u8, source.column),
        };
    }

    return filter_columns;
}

fn copyCStringArray(
    allocator: Allocator,
    count: usize,
    strings: [*c][*c]u8,
) Allocator.Error![][]u8 {
    const values = try allocator.alloc([]u8, count);
    errdefer allocator.free(values);

    for (values, 0..) |*value, index| {
        value.* = try dupCString(allocator, strings[index]);
    }

    return values;
}

fn copyGeneratedStringArray(allocator: Allocator, strings: []const []const u8) Allocator.Error![][]u8 {
    const values = try allocator.alloc([]u8, strings.len);
    errdefer allocator.free(values);

    for (values, strings) |*value, source| {
        value.* = try allocator.dupe(u8, source);
    }

    return values;
}

fn uniqueStringsFromTables(allocator: Allocator, tables_info: []const Table) Allocator.Error![][]const u8 {
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    var result = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    for (tables_info) |table| {
        if (seen.contains(table.name)) continue;
        try seen.put(table.name, {});
        try result.append(allocator, table.name);
    }

    return result.toOwnedSlice(allocator);
}

fn filterTableNamesByContext(
    allocator: Allocator,
    tables_info: []const Table,
    context: Context,
) Allocator.Error![][]const u8 {
    var result = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    for (tables_info) |table| {
        if (table.context == context) try result.append(allocator, table.name);
    }

    return result.toOwnedSlice(allocator);
}

fn uniqueStringsFromFunctions(allocator: Allocator, functions_info: []const Function) Allocator.Error![][]const u8 {
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    var result = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    for (functions_info) |function| {
        if (seen.contains(function.name)) continue;
        try seen.put(function.name, {});
        try result.append(allocator, function.name);
    }

    return result.toOwnedSlice(allocator);
}

fn filterFunctionNamesByContext(
    allocator: Allocator,
    functions_info: []const Function,
    context: Context,
) Allocator.Error![][]const u8 {
    var result = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    errdefer result.deinit(allocator);

    for (functions_info) |function| {
        if (function.context == context) try result.append(allocator, function.name);
    }

    return result.toOwnedSlice(allocator);
}

fn contextFromSummary(context: c.PgQuery__SummaryResult__Context) Context {
    return switch (context) {
        c.PG_QUERY__SUMMARY_RESULT__CONTEXT__Select => .select,
        c.PG_QUERY__SUMMARY_RESULT__CONTEXT__DML => .dml,
        c.PG_QUERY__SUMMARY_RESULT__CONTEXT__DDL => .ddl,
        c.PG_QUERY__SUMMARY_RESULT__CONTEXT__Call => .call,
        else => .none,
    };
}

fn contextFromGenerated(context: root.pb.SummaryResult.Context) Context {
    return switch (context) {
        .Select => .select,
        .DML => .dml,
        .DDL => .ddl,
        .Call => .call,
        else => .none,
    };
}

fn dupCString(allocator: Allocator, source: [*c]u8) Allocator.Error![]u8 {
    return allocator.dupe(u8, std.mem.span(source));
}

fn dupOptionalCString(allocator: Allocator, source: [*c]u8) Allocator.Error!?[]u8 {
    if (source == null) return null;
    const value = std.mem.span(source);
    if (value.len == 0) return null;
    const duped = try allocator.dupe(u8, value);
    return duped;
}
