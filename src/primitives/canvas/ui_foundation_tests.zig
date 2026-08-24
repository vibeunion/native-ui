const std = @import("std");
const foundation = @import("ui_foundation.zig");

test "public UI foundation inventory is complete and unique" {
    try std.testing.expectEqual(@as(u32, 1), foundation.schema_version);
    try std.testing.expectEqual(@as(usize, 5), foundation.templates.len);
    for (foundation.templates, 0..) |template, index| {
        try std.testing.expect(template.name.len > 0);
        try std.testing.expect(template.role.len > 0);
        try std.testing.expect(foundation.find(template.name) != null);
        for (foundation.templates[index + 1 ..]) |other| {
            try std.testing.expect(!std.mem.eql(u8, template.name, other.name));
        }
    }
    try std.testing.expect(foundation.find("private-sidebar") == null);
}

test "public workbench metrics stay platform-neutral and bounded" {
    const metrics = foundation.WorkbenchMetrics;
    try std.testing.expect(metrics.toolbar_height >= metrics.action_size);
    try std.testing.expect(metrics.sidebar_min_width <= metrics.sidebar_preferred_width);
    try std.testing.expect(metrics.sidebar_preferred_width <= metrics.sidebar_max_width);
    try std.testing.expect(metrics.navigation_row_height >= 28);
    try std.testing.expect(metrics.composer_min_height >= 64);
    try std.testing.expect(metrics.content_max_width <= metrics.composer_content_max_width);
}
