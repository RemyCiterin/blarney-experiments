const std = @import("std");
const Target = std.Target;
const Feature = Target.riscv.Feature;
const config = @import("src/config.zig").config;

const XLEN = 32;

const Command = struct {
    allocator: std.mem.Allocator,

    args: std.ArrayList([]u8),

    pub fn append(this: *@This(), arg: []const u8) !void {
        const copy = try this.allocator.alloc(u8, arg.len);
        @memcpy(copy, arg);

        try this.args.append(copy);
    }

    pub fn appendSlice(this: *@This(), args: []const []const u8) !void {
        for (args) |arg| try this.append(arg);
    }

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
            .args = std.ArrayList([]u8).init(allocator),
        };
    }

    pub fn deinit(this: @This()) void {
        for (this.args.items) |arg| {
            this.allocator.free(arg);
        }

        this.args.deinit();
    }
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const target = std.Target.Query{
        .cpu_arch = Target.Cpu.Arch.riscv32,
        .cpu_model = .{ .explicit = &Target.riscv.cpu.generic_rv32 },
        .cpu_features_add = Target.riscv.featureSet(&[_]Feature{
            .zicbom,
            .a,
        }),
        .os_tag = .freestanding,
        .abi = .none, // .eabi
    };

    const optimize = b.standardOptimizeOption(.{}); // .ReleaseSmall;
    const optimizeSmall = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    }); // .ReleaseSmall;

    const exe = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
    });

    const bootloader = b.addExecutable(.{
        .name = "bootloader.elf",
        .root_source_file = .{ .cwd_relative = "src/boot.zig" },
        .target = b.resolveTargetQuery(target),
        .optimize = optimizeSmall,
    });

    exe.addAssemblyFile(.{ .cwd_relative = "src/trampoline.s" });
    exe.addAssemblyFile(.{ .cwd_relative = "src/init.S" });

    bootloader.addAssemblyFile(.{ .cwd_relative = "src/trampoline.s" });
    bootloader.addAssemblyFile(.{ .cwd_relative = "src/init.S" });

    //exe.code_model = .medium;

    exe.setLinkerScriptPath(.{ .cwd_relative = "src/linker_kernel.ld" });
    bootloader.setLinkerScriptPath(.{ .cwd_relative = "src/linker_boot.ld" });

    b.installArtifact(exe);
    b.installArtifact(bootloader);
}
