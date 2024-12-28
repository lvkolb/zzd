const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zzd",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add the executable installation step
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the hexdump utility");
    run_step.dependOn(&run_cmd.step);

    // Create a custom step to copy the executable to /usr/local/bin/
    const copy_step = b.addSystemCommand(&.{
        "cp",
        b.getInstallPath(.bin, exe.out_filename),
        "/usr/local/bin/zzd",
    });

    const install_step = b.step("install-to-bin", "Copy executable to /usr/local/bin/");
    install_step.dependOn(&copy_step.step);
    install_step.dependOn(b.getInstallStep());
}


