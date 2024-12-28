const std = @import("std");

const DisplayRadix = enum(u8) {
    hex,
    decimal,
    octal,
    binary,
};
//----------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------

const OptionalConfig = struct {
    limit: ?usize = null,
    skip: ?usize = null,
    pattern_search: ?[]const u8 = null,
};
const Color = enum {
    red,
    green,
    blue,
};
const Options = struct {
    line_length: u8 = 16,
    group_size: u8 = 1,
    display_radix: DisplayRadix = .hex,
    big_endian: bool = false,
    show_ascii: bool = true,
    show_offset: bool = true,
    color_output: bool = true,
    highlights: std.ArrayList([]const u8),
    highlight_color: Color = .red,
    optional: OptionalConfig = .{},

    //----------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------
    //error handling at comptime
    pub fn validate(self: Options) !void {
        if (self.line_length == 0 or self.line_length > 64) {
            return error.InvalidLineLength;
        }
        if (self.group_size > self.line_length) {
            return error.InvalidGroupSize;
        }
    }
};
//----------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------
//errors
const HexdumpError = error{
    InvalidLineLength,
    InvalidGroupSize,
    InvalidHexPattern,
    FileReadError,
    OutOfMemory,
    InvalidArguments,
};

pub fn main() !void {
    //----------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------
    //The arena allocates memory from the operating system's page allocator
    //but instead of freeing each allocation individually, it keeps track of everything and frees it all at once.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2 or (args.len == 2 and std.mem.eql(u8, args[1], "--help"))) {
        try printHelp(std.io.getStdOut().writer(), args[0]);
        return;
    }

    var highlights = std.ArrayList([]const u8).init(allocator);
    defer highlights.deinit();

    var options = Options{
        .highlights = highlights,
    };

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "--line-length=")) {
            const value = arg[13..];
            const parsed = try std.fmt.parseInt(u8, value, 10);
            options.line_length = @min(parsed, 64);
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            const value = arg[8..];
            options.optional.limit = try std.fmt.parseInt(usize, value, 10);
        } else if (std.mem.startsWith(u8, arg, "--skip=")) {
            const value = arg[7..];
            options.optional.skip = try std.fmt.parseInt(usize, value, 10);
        } else if (std.mem.startsWith(u8, arg, "--highlight=")) {
            const value_start = 12;
            const value = arg[value_start..];
            try options.highlights.append(try parseHexPattern(value, allocator));
            //----------------------------------------------------------------------------------------------------------
            //-----------------------------------------------------------------------------------------------------------

        } else if (std.mem.startsWith(u8, arg, "--color=")) {
            const value = arg[8..];
            if (std.mem.eql(u8, value, "red")) {
                options.highlight_color = .red;
            } else if (std.mem.eql(u8, value, "green")) {
                options.highlight_color = .green;
            } else if (std.mem.eql(u8, value, "blue")) {
                options.highlight_color = .blue;
            } else {
                std.debug.print("Invalid color: {s}\n", .{value});
                return error.InvalidArguments;
            }
        } else if (std.mem.startsWith(u8, arg, "--pattern=")) {
            options.optional.pattern_search = try parseHexPattern(arg[10..], allocator);
        } else if (std.mem.startsWith(u8, arg, "--group=")) {
            const value = arg[8..];
            options.group_size = try std.fmt.parseInt(u8, value, 10);
        } else if (std.mem.eql(u8, arg, "--no-ascii")) {
            options.show_ascii = false;
        } else if (std.mem.eql(u8, arg, "--no-offset")) {
            options.show_offset = false;
        } else if (std.mem.eql(u8, arg, "--decimal")) {
            options.display_radix = .decimal;
        } else if (std.mem.eql(u8, arg, "--octal")) {
            options.display_radix = .octal;
        } else if (std.mem.eql(u8, arg, "--binary")) {
            options.display_radix = .binary;
        } else {
            std.debug.print("Invalid argument: {s}\n", .{arg});
            return error.InvalidArguments;
        }
    }

    try options.validate();
    try processFile(args[1], options, allocator);
}

fn processFile(filename: []const u8, options: Options, allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stdout = std.io.getStdOut().writer();
    var buffer = try allocator.alloc(u8, options.line_length);

    defer allocator.free(buffer);

    if (options.optional.skip) |skip| {
        try file.seekTo(skip);
    }

    var offset: usize = if (options.optional.skip) |skip| skip else 0;
    var total_bytes_read: usize = 0;

    var pattern_buffer: ?[]u8 = null;
    defer if (pattern_buffer) |p| allocator.free(p);

    if (options.optional.pattern_search) |pattern| {
        pattern_buffer = try allocator.dupe(u8, pattern);
    }

    var found_pattern = false;
    while (true) {
        const bytes_read = try file.read(buffer);
        if (bytes_read == 0) break;

        if (pattern_buffer) |pattern| {
            if (findPattern(buffer[0..bytes_read], pattern)) |_| {
                found_pattern = true;
            } else if (!found_pattern) {
                offset += bytes_read;
                continue;
            }
        }
        //----------------------------------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------------------------------
        //unpacking
        if (options.optional.limit) |limit| {
            if (total_bytes_read + bytes_read > limit) {
                const bytes_to_print = limit - total_bytes_read;
                if (bytes_to_print == 0) break;
                try printLine(stdout, offset, buffer[0..bytes_to_print], options);
                break;
            }
        }

        total_bytes_read += bytes_read;
        try printLine(stdout, offset, buffer[0..bytes_read], options);
        offset += bytes_read;

        if (options.optional.limit) |limit| {
            if (total_bytes_read >= limit) break;
        }
    }
}

fn findPattern(buffer: []const u8, pattern: []const u8) ?usize {
    if (pattern.len > buffer.len) return null;
    return std.mem.indexOf(u8, buffer, pattern);
}

fn isValidHexChar(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

fn parseHexPattern(pattern: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const trimmed = std.mem.trim(u8, pattern, " \t\n\r\"'");

    if (trimmed.len == 0) return error.InvalidHexPattern;

    for (trimmed) |c| {
        if (!(c >= '0' and c <= '9') and !(c >= 'a' and c <= 'f') and !(c >= 'A' and c <= 'F')) {
            std.debug.print("Invalid character: {c}\n", .{c});
            return error.InvalidHexPattern;
        }
    }

    const bytes_needed = (trimmed.len + 1) / 2;
    var result = try allocator.alloc(u8, bytes_needed);
    errdefer allocator.free(result);

    var padded: [3]u8 = undefined;
    var i: usize = 0;
    while (i < trimmed.len) {
        const remaining = trimmed.len - i;
        const slice = if (remaining == 1) blk: {
            padded[0] = '0';
            padded[1] = trimmed[i];
            break :blk padded[0..2];
        } else trimmed[i .. i + 2];

        result[i / 2] = std.fmt.parseInt(u8, slice, 16) catch {
            std.debug.print("Failed to parse slice: '{s}'\n", .{slice});
            return error.InvalidHexPattern;
        };

        i += 2;
        if (remaining == 1) break;
    }

    return result;
}
fn getColorCode(color: Color) []const u8 {
    switch (color) {
        .red => return "\x1b[31m",
        .green => return "\x1b[32m",
        //\x1b[33m
        .blue => return "\x1b[34m",
    }
}
fn printLine(writer: anytype, offset: usize, buffer: []const u8, options: Options) !void {
    if (options.show_offset) {
        try writer.print("{X:0>8}  ", .{offset});
    }
    const color_code = getColorCode(options.highlight_color);
    //----------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------
    //const color_code2 = getColorCode(options.highlight_color);
    var i: usize = 0;
    while (i < options.line_length) {
        if (i < buffer.len) {
            var matched_pattern_len: usize = 0;

            for (options.highlights.items) |pattern| {
                if (i + pattern.len <= buffer.len and std.mem.eql(u8, buffer[i .. i + pattern.len], pattern)) {
                    matched_pattern_len = pattern.len;
                    break;
                }
            }
            if (options.group_size > 0 and (i) % options.group_size == 0 and i < options.line_length) {
                try writer.writeAll(" ");
            }

            if (matched_pattern_len > 0 and options.color_output) {
                try writer.writeAll(color_code);
            }

            const range_end = if (matched_pattern_len > 0) i + matched_pattern_len else i + 1;
            for (buffer[i..range_end]) |byte| {
                //----------------------------------------------------------------------------------------------------------
                //-----------------------------------------------------------------------------------------------------------
                //printf("%02X", byte)
                switch (options.display_radix) {
                    .hex => try writer.print("{X:0>2} ", .{byte}),
                    .decimal => try writer.print("{d:>3} ", .{byte}),
                    .octal => try writer.print("{o:>3} ", .{byte}),
                    .binary => try writer.print("{b:0>8} ", .{byte}),
                }
            }

            if (matched_pattern_len > 0 and options.color_output) {
                try writer.writeAll("\x1b[0m");
            }
            i = range_end;
        } else {
            switch (options.display_radix) {
                .hex => try writer.writeByteNTimes(' ', 3),
                .decimal => try writer.writeByteNTimes(' ', 4),
                .octal => try writer.writeByteNTimes(' ', 4),
                .binary => try writer.writeByteNTimes(' ', 9),
            }
            i += 1;
        }
    }

    if (options.show_ascii) {
        try writer.writeAll(" |");
        var idx: usize = 0;

        while (idx < buffer.len) {
            var matched_pattern_len: usize = 0;

            for (options.highlights.items) |pattern| {
                if (idx + pattern.len <= buffer.len and std.mem.eql(u8, buffer[idx .. idx + pattern.len], pattern)) {
                    matched_pattern_len = pattern.len;
                    break;
                }
            }

            if (matched_pattern_len > 0 and options.color_output) {
                try writer.writeAll(color_code);
            }

            const ascii_end = if (matched_pattern_len > 0) idx + matched_pattern_len else idx + 1;
            for (buffer[idx..ascii_end]) |c| {
                if (std.ascii.isPrint(c)) {
                    try writer.writeByte(c);
                } else {
                    try writer.writeByte('.');
                }
            }

            if (matched_pattern_len > 0 and options.color_output) {
                try writer.writeAll("\x1b[0m");
            }

            idx = ascii_end;
        }

        for (buffer.len..options.line_length) |_| {
            try writer.writeByte(' ');
        }
        try writer.writeAll("|\n");
    } else {
        try writer.writeByte('\n');
    }
}

fn printHelp(writer: anytype, program_name: []const u8) !void {
    try writer.print(
        \\Usage: {s} <filename> [options]
        \\
        \\Options:
        \\  Display Options:
        \\    --line-length=<n>   Set the number of bytes per line (default: 16, max: 64)
        \\    --group=<n>         Group bytes in sets of n (default: 1)
        \\    --no-ascii          Don't display ASCII representation
        \\    --no-offset         Don't display offset column
        \\    --color=<n>
        \\
        \\  Number Format Options:
        \\    (default: hex)      Display numbers in hexadecimal
        \\    --decimal           Display numbers in decimal
        \\    --octal            Display numbers in octal
        \\    --binary           Display numbers in binary
        \\
        \\  Data Selection:
        \\    --limit=<n>         Limit the number of bytes displayed
        \\    --skip=<n>          Skip first n bytes of input
        \\
        \\  Pattern Matching:
        \\    --highlight=<hex>   Highlight specific byte sequences (can be used multiple times)
        \\
    , .{program_name});
}
