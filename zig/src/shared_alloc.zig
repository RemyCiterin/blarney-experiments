//! This module build a memory allocator protected by a spinlock,
//! so it can be used by multiple parallel threads. This lock
//! is a spinlock so it just wait for it to be ready

const std = @import("std");
const mem = std.mem;

const Spinlock = @import("spinlock.zig");

lock: Spinlock = .{},
kalloc: std.mem.Allocator,

pub fn init(kalloc: std.mem.Allocator) @This() {
    return .{ .kalloc = kalloc };
}

pub fn allocator(self: *@This()) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .remap = remap,
            .resize = resize,
            .free = free,
        },
    };
}

pub fn alloc(
    ctx: *anyopaque,
    len: usize,
    alignment: std.mem.Alignment,
    ret_addr: usize,
) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    self.lock.lock();
    defer self.lock.unlock();

    return self.kalloc.vtable.alloc(
        self.kalloc.ptr,
        len,
        alignment,
        ret_addr,
    );
}

pub fn resize(
    ctx: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    ret_addr: usize,
) bool {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    self.lock.lock();
    defer self.lock.unlock();

    return self.kalloc.vtable.resize(
        self.kalloc.ptr,
        memory,
        alignment,
        new_len,
        ret_addr,
    );
}

pub fn remap(
    ctx: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    ret_addr: usize,
) ?[*]u8 {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    self.lock.lock();
    defer self.lock.unlock();

    return self.kalloc.vtable.remap(
        self.kalloc.ptr,
        memory,
        alignment,
        new_len,
        ret_addr,
    );
}

pub fn free(
    ctx: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    ret_addr: usize,
) void {
    const self: *@This() = @ptrCast(@alignCast(ctx));

    self.lock.lock();
    defer self.lock.unlock();

    self.kalloc.vtable.free(
        self.kalloc.ptr,
        memory,
        alignment,
        ret_addr,
    );
}
