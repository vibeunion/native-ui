const std = @import("std");
const canvas = @import("root.zig");
const ui_library = canvas.ui_library;

const Msg = enum { activate, hover_enter, hover_leave };
const TestUi = canvas.Ui(Msg);

const InventoryReceipt = struct {
    schema_version: u32,
    generated_by: []const u8,
    sources: []const SourceReceipt,
};

const SourceReceipt = struct {
    source: []const u8,
    repository: []const u8,
    revision: []const u8,
    authoritative_path: []const u8,
    source_sha256: []const u8,
    modules: []const []const u8,
};

fn findReceiptSource(sources: []const SourceReceipt, source: []const u8) ?*const SourceReceipt {
    for (sources) |*item| {
        if (std.mem.eql(u8, item.source, source)) return item;
    }
    return null;
}

fn receiptContains(modules: []const []const u8, module: []const u8) bool {
    for (modules) |candidate| {
        if (std.mem.eql(u8, candidate, module)) return true;
    }
    return false;
}

test "GPUI reference inventories are complete, unique, and publicly reachable" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const receipt = try std.json.parseFromSliceLeaky(
        InventoryReceipt,
        arena_state.allocator(),
        @embedFile("testdata/ui_library_inventory_receipt.json"),
        .{ .ignore_unknown_fields = false },
    );

    try std.testing.expectEqual(@as(u32, 1), receipt.schema_version);
    try std.testing.expectEqualStrings("scripts/update-ui-library-inventory.mjs", receipt.generated_by);
    try std.testing.expectEqual(@as(usize, 2), receipt.sources.len);

    const zed = findReceiptSource(receipt.sources, "zed_ui").?;
    const gpui_component = findReceiptSource(receipt.sources, "gpui_component").?;
    try std.testing.expectEqualStrings(ui_library.zed_ui_repository, zed.repository);
    try std.testing.expectEqualStrings(ui_library.gpui_component_repository, gpui_component.repository);
    try std.testing.expectEqualStrings(ui_library.zed_ui_reference_sha, zed.revision);
    try std.testing.expectEqualStrings(ui_library.gpui_component_reference_sha, gpui_component.revision);
    try std.testing.expectEqualStrings(ui_library.zed_ui_authoritative_path, zed.authoritative_path);
    try std.testing.expectEqualStrings(ui_library.gpui_component_authoritative_path, gpui_component.authoritative_path);
    try std.testing.expectEqualStrings(ui_library.zed_ui_source_sha256, zed.source_sha256);
    try std.testing.expectEqualStrings(ui_library.gpui_component_source_sha256, gpui_component.source_sha256);
    try std.testing.expectEqual(ui_library.zed_ui_module_count, zed.modules.len);
    try std.testing.expectEqual(ui_library.gpui_component_module_count, gpui_component.modules.len);

    try std.testing.expectEqual(ui_library.zed_ui_module_count, ui_library.count(.zed_ui));
    try std.testing.expectEqual(ui_library.gpui_component_module_count, ui_library.count(.gpui_component));
    try std.testing.expectEqual(
        ui_library.zed_ui_module_count + ui_library.gpui_component_module_count,
        ui_library.entries.len,
    );

    for (zed.modules) |module| try std.testing.expect(ui_library.find(.zed_ui, module) != null);
    for (gpui_component.modules) |module| try std.testing.expect(ui_library.find(.gpui_component, module) != null);

    inline for (ui_library.entries, 0..) |item, index| {
        try std.testing.expect(item.module.len > 0);
        try std.testing.expect(item.native_entry.len > 0);
        try std.testing.expect(item.note.len > 0);

        for (ui_library.entries[index + 1 ..]) |other| {
            if (item.source == other.source) {
                try std.testing.expect(!std.mem.eql(u8, item.module, other.module));
            }
        }

        switch (item.entry_point_kind) {
            .ui_builder => {
                try std.testing.expect(std.mem.startsWith(u8, item.native_entry, "Ui."));
                try std.testing.expect(@hasDecl(TestUi, item.native_entry[3..]));
            },
            .canvas_api => {
                try std.testing.expect(std.mem.startsWith(u8, item.native_entry, "canvas."));
                try std.testing.expect(@hasDecl(canvas, item.native_entry[7..]));
            },
            .platform_api => try std.testing.expectEqualStrings("platform.PlatformServices.readClipboard", item.native_entry),
            .caller_model => try std.testing.expectEqualStrings("Ui(Msg)", item.native_entry),
        }

        const source_modules = switch (item.source) {
            .zed_ui => zed.modules,
            .gpui_component => gpui_component.modules,
        };
        try std.testing.expect(receiptContains(source_modules, item.module));
    }
}

test "reference module lookup covers both pinned catalogs" {
    try std.testing.expectEqualStrings(
        "Ui.banner",
        ui_library.find(.zed_ui, "banner").?.native_entry,
    );
    try std.testing.expectEqualStrings(
        "Ui.commandPalette",
        ui_library.find(.gpui_component, "command").?.native_entry,
    );
    try std.testing.expect(ui_library.find(.zed_ui, "not-a-module") == null);
}

test "named retained-widget constructors build their exact widget kinds" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var ui = TestUi.init(arena_state.allocator());

    const nodes = [_]TestUi.Node{
        ui.grid(.{}, .{}),
        ui.dataGrid(.{}, .{}),
        ui.table(.{}, .{}),
        ui.dataRow(.{}, .{}),
        ui.dataCell(.{}, "Cell"),
        ui.breadcrumb(.{}, .{}),
        ui.buttonGroup(.{}, .{}),
        ui.pagination(.{}, .{}),
        ui.radioGroup(.{ .semantics = .{ .label = "Choice" } }, .{}),
        ui.tabs(.{}, .{}),
        ui.toggleGroup(.{}, .{}),
        ui.accordion(.{}, .{}),
        ui.alert(.{}, .{}),
        ui.bubble(.{}, .{}),
        ui.card(.{}, .{}),
        ui.dialog(.{}, .{}),
        ui.drawer(.{}, .{}),
        ui.sheet(.{}, .{}),
        ui.resizable(.{}, .{}),
        ui.popover(.{}, .{}),
        ui.menuSurface(.{}, .{}),
        ui.dropdownMenu(.{}, .{}),
        ui.badge(.{}, "Badge"),
        ui.toggleButton(.{}, "Toggle button"),
        ui.iconButton(.{ .icon = "plus", .semantics = .{ .label = "Add" } }),
        ui.menuItem(.{}, "Menu item"),
        ui.radio(.{ .semantics = .{ .label = "Radio" } }),
        ui.switchControl(.{ .semantics = .{ .label = "Switch" } }),
        ui.toggle(.{}, "Toggle"),
        ui.slider(.{ .semantics = .{ .label = "Value" } }),
        ui.progress(.{ .semantics = .{ .label = "Progress" } }),
        ui.segmentedControl(.{}, .{}),
        ui.select(.{ .semantics = .{ .label = "Select" } }, "Current"),
        ui.input(.{ .semantics = .{ .label = "Input" } }),
        ui.searchField(.{ .semantics = .{ .label = "Search" } }),
        ui.combobox(.{ .semantics = .{ .label = "Combobox" } }),
        ui.textarea(.{ .semantics = .{ .label = "Textarea" } }),
        ui.tooltip(.{}, "Tooltip"),
        ui.skeleton(.{ .width = 40, .height = 12 }),
        ui.spinner(.{ .semantics = .{ .label = "Loading" } }),
    };

    const expected = [_]canvas.WidgetKind{
        .grid,
        .data_grid,
        .table,
        .data_row,
        .data_cell,
        .breadcrumb,
        .button_group,
        .pagination,
        .radio_group,
        .tabs,
        .toggle_group,
        .accordion,
        .alert,
        .bubble,
        .card,
        .dialog,
        .drawer,
        .sheet,
        .resizable,
        .popover,
        .menu_surface,
        .dropdown_menu,
        .badge,
        .toggle_button,
        .icon_button,
        .menu_item,
        .radio,
        .switch_control,
        .toggle,
        .slider,
        .progress,
        .segmented_control,
        .select,
        .input,
        .search_field,
        .combobox,
        .textarea,
        .tooltip,
        .skeleton,
        .spinner,
    };

    for (nodes, expected) |node, kind| try std.testing.expectEqual(kind, node.widget.kind);
    try std.testing.expectEqualStrings("Cell", nodes[4].widget.text);
    try std.testing.expectEqualStrings("Badge", nodes[22].widget.text);
    try std.testing.expectEqualStrings("Tooltip", nodes[37].widget.text);
}

test "semantic aliases lower to stateless retained-widget composites" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var ui = TestUi.init(arena_state.allocator());

    const avatar_a = ui.avatar(.{}, "AA");
    const avatar_b = ui.avatar(.{}, "BB");
    const search = ui.searchField(.{ .semantics = .{ .label = "Search" } });
    const results = ui.list(.{}, .{ui.listItem(.{ .on_press = .activate }, "Result")});
    const pane_a = ui.panel(.{ .min_width = 80 }, .{});
    const pane_b = ui.panel(.{ .min_width = 80 }, .{});
    const values = [_]f32{ 0, 1, 0.5 };
    const series = [_]canvas.ChartSeries{.{ .values = &values }};

    const nodes = [_]TestUi.Node{
        ui.banner(.{}, .{ui.text(.{}, "Banner")}),
        ui.callout(.{}, .{ui.text(.{}, "Callout")}),
        ui.notification(.{}, .{ui.text(.{}, "Notice")}),
        ui.chip(.{}, "Chip"),
        ui.tagBadge(.{}, "Tag"),
        ui.countBadge(.{}, 7),
        ui.statusIndicator(.{}, "Ready"),
        ui.kbd(.{}, "Cmd K"),
        ui.keybinding(.{}, "Cmd P"),
        ui.keybindingHint(.{}, "Enter"),
        ui.divider(.{}),
        ui.facepile(.{}, .{ avatar_a, avatar_b }),
        ui.group(.{}, .{ui.text(.{}, "Grouped")}),
        ui.modal(.{}, .{ui.text(.{}, "Modal")}),
        ui.popoverMenu(.{}, .{ui.menuItem(.{}, "Open")}),
        ui.menu(.{}, .{ui.menuItem(.{}, "Open")}),
        ui.tab(.{ .selected = true }, "Active"),
        ui.tabBar(.{}, .{}),
        ui.treeViewItem(.{}, "Node"),
        ui.dataTable(.{}, .{}),
        ui.diffStat(.{}, .{ ui.badge(.{}, "+3"), ui.badge(.{}, "-1") }),
        ui.disclosure(.{}, .{}),
        ui.redistributableColumns(.{ .value = 0.4 }, .{ pane_a, pane_b }),
        ui.stickyItems(.{}, ui.text(.{}, "Header"), ui.scroll(.{}, .{})),
        ui.emptyState(.{}, .{ui.text(.{}, "Empty")}),
        ui.groupBox(.{}, .{ui.text(.{}, "Group box")}),
        ui.collapsible(.{}, .{}),
        ui.sidebar(.{}, .{ui.listItem(.{}, "Inbox")}),
        ui.rating(.{ .semantics = .{ .label = "Rating" } }, .{}),
        ui.colorPicker(.{}, .{}),
        ui.form(.{}, .{search}),
        ui.setting(.{}, .{ ui.textLabel(.{}, "Setting"), ui.switchControl(.{ .semantics = .{ .label = "Enabled" } }) }),
        ui.commandPalette(.{}, search, results),
        ui.history(.{}, .{}),
        ui.searchableList(.{}, search, results),
        ui.hoverCard(.{}, ui.text(.{}, "Hover trigger"), .{ui.text(.{}, "Details")}),
        ui.descriptionList(.{}, .{}),
        ui.highlighter(.{ .language = .zig }, "const x = 1;"),
        ui.plot(.{}, &series),
        ui.dock(.{ .value = 0.5 }, .{ pane_a, pane_b }),
    };

    const root = ui.column(.{ .gap = 4 }, .{nodes});
    const tree = try ui.finalize(root);
    try std.testing.expectEqual(canvas.WidgetKind.column, tree.root.kind);
    try std.testing.expectEqual(nodes.len, tree.root.children.len);
    try std.testing.expectEqual(canvas.WidgetRole.treeitem, nodes[18].widget.semantics.role);
    try std.testing.expectEqual(canvas.WidgetRole.radiogroup, nodes[28].widget.semantics.role);
    try std.testing.expectEqual(canvas.WidgetKind.chart, nodes[38].widget.kind);
    try std.testing.expectEqual(canvas.WidgetKind.split, nodes[39].widget.kind);
}

test "hover card exposes caller-owned closed and open lifecycle" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var ui = TestUi.init(arena_state.allocator());

    const closed = ui.hoverCard(.{
        .on_hover_enter = .hover_enter,
        .on_hover_leave = .hover_leave,
    }, ui.button(.{}, "Inspect"), .{ui.text(.{}, "Details")});
    const closed_tree = try ui.finalize(closed);
    try std.testing.expectEqual(canvas.WidgetKind.stack, closed_tree.root.kind);
    try std.testing.expectEqual(@as(usize, 1), closed_tree.root.children.len);
    const closed_trigger = closed_tree.root.children[0];
    try std.testing.expectEqual(Msg.hover_enter, closed_tree.msgFor(closed_trigger.id, .hover_enter).?);
    try std.testing.expectEqual(Msg.hover_leave, closed_tree.msgFor(closed_trigger.id, .hover_leave).?);

    var open_ui = TestUi.init(arena_state.allocator());
    const open = open_ui.hoverCard(.{
        .open = true,
        .on_hover_enter = .hover_enter,
        .on_hover_leave = .hover_leave,
        .placement = .above,
        .alignment = .end,
        .offset = 9,
    }, open_ui.button(.{}, "Inspect"), .{open_ui.text(.{}, "Details")});
    const open_tree = try open_ui.finalize(open);
    try std.testing.expectEqual(@as(usize, 2), open_tree.root.children.len);
    const open_trigger = open_tree.root.children[0];
    const open_card = open_tree.root.children[1];
    try std.testing.expectEqual(canvas.WidgetKind.popover, open_card.kind);
    try std.testing.expectEqual(canvas.WidgetAnchorPlacement.above, open_card.layout.anchor.?.placement);
    try std.testing.expectEqual(canvas.WidgetAnchorAlignment.end, open_card.layout.anchor.?.alignment);
    try std.testing.expectEqual(@as(f32, 9), open_card.layout.anchor.?.offset);
    try std.testing.expectEqual(Msg.hover_enter, open_tree.msgFor(open_trigger.id, .hover_enter).?);
    try std.testing.expectEqual(Msg.hover_leave, open_tree.msgFor(open_trigger.id, .hover_leave).?);
    try std.testing.expectEqual(Msg.hover_enter, open_tree.msgFor(open_card.id, .hover_enter).?);
    try std.testing.expectEqual(Msg.hover_leave, open_tree.msgFor(open_card.id, .hover_leave).?);
}

test "context-menu aliases copy caller items and preserve typed messages" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var ui = TestUi.init(arena_state.allocator());

    const items = [_]TestUi.ContextMenuItem{.{ .label = "Open", .msg = .activate }};
    const node = ui.rightClickMenu(ui.panel(.{}, .{}), &items);
    try std.testing.expectEqual(@as(usize, 1), node.context_menu.len);
    try std.testing.expectEqualStrings("Open", node.context_menu[0].label);
    try std.testing.expectEqual(Msg.activate, node.context_menu[0].msg.?);
}
