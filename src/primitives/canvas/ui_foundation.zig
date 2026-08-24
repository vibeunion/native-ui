//! Public, stateless workbench UI foundation.
//!
//! These declarations are vocabulary and geometry defaults only. Product
//! state, labels, selection, navigation, pending/result state, and messages
//! stay in the caller-owned Model/Msg/update loop.

const std = @import("std");

pub const schema_version: u32 = 1;
pub const template_source_path = "src/tooling/components/ui_foundation.native";
pub const template_source = @embedFile("../../tooling/components/ui_foundation.native");

pub const WorkbenchMetrics = struct {
    pub const toolbar_height: f32 = 46;
    pub const action_size: f32 = 28;
    pub const sidebar_min_width: f32 = 240;
    pub const sidebar_preferred_width: f32 = 275;
    pub const sidebar_max_width: f32 = 520;
    pub const navigation_row_height: f32 = 31;
    pub const composer_min_height: f32 = 96;
    pub const composer_content_max_width: f32 = 790;
    pub const content_max_width: f32 = 768;
};

pub const Template = struct {
    name: []const u8,
    role: []const u8,
};

pub const templates = [_]Template{
    .{ .name = "ui-foundation-toolbar", .role = "toolbar-frame" },
    .{ .name = "ui-foundation-sidebar", .role = "sidebar-frame" },
    .{ .name = "ui-foundation-composer", .role = "composer-frame" },
    .{ .name = "ui-foundation-panel", .role = "panel-frame" },
    .{ .name = "ui-foundation-timeline", .role = "timeline-frame" },
};

pub fn find(name: []const u8) ?*const Template {
    for (&templates) |*template| {
        if (std.mem.eql(u8, template.name, name)) return template;
    }
    return null;
}
