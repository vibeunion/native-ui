//! Public UI-library parity registry.
//!
//! The registry maps the complete public module inventories of two pinned
//! GPUI ecosystem references onto Native SDK's public APIs. It records
//! coverage, not runtime adoption: GPUI application/global/window ownership is
//! deliberately absent, while every component module has a concrete Native
//! entry point or an explicit caller/platform-owned authority.

pub const zed_ui_reference_sha = "6bf539cd52126974eb0dbff667de02a696a737ec";
pub const gpui_component_reference_sha = "334bbed2e8c47d606eb79ab05ddcebd60b823429";
pub const zed_ui_repository = "https://github.com/zed-industries/zed";
pub const gpui_component_repository = "https://github.com/longbridge/gpui-component";
pub const zed_ui_authoritative_path = "crates/ui/src/components.rs";
pub const gpui_component_authoritative_path = "crates/ui/src/lib.rs";
pub const zed_ui_source_sha256 = "8fe7f9a956ef78b81d9f5fb2680d7a8d7d0ac0530f060ddca697dd0827e73109";
pub const gpui_component_source_sha256 = "8aaaf92f9b4df69a1a126eeecc8ae1fff1c3f42c8d03815a1cf359d282de2102";
pub const zed_ui_module_count: usize = 42;
pub const gpui_component_module_count: usize = 57;

pub const ReferenceSource = enum {
    zed_ui,
    gpui_component,
};

pub const Coverage = enum {
    direct_widget,
    stateless_composite,
    runtime_surface,
    algorithm_contract,
    platform_owned,
    caller_owned,
    product_composition,
};

pub const EntryPointKind = enum {
    ui_builder,
    canvas_api,
    platform_api,
    caller_model,
};

pub const Entry = struct {
    source: ReferenceSource,
    module: []const u8,
    coverage: Coverage,
    entry_point_kind: EntryPointKind,
    native_entry: []const u8,
    note: []const u8,
};

pub const entries = [_]Entry{
    // Zed crates/ui public modules at zed_ui_reference_sha.
    entry(.zed_ui, "ai", .product_composition, .ui_builder, "Ui.column", "Product UI composes ordinary caller-owned content."),
    entry(.zed_ui, "avatar", .direct_widget, .ui_builder, "Ui.avatar", "Registered image with initials fallback."),
    entry(.zed_ui, "banner", .stateless_composite, .ui_builder, "Ui.banner", "Alert-backed banner composition."),
    entry(.zed_ui, "button", .direct_widget, .ui_builder, "Ui.button", "Native retained button."),
    entry(.zed_ui, "callout", .stateless_composite, .ui_builder, "Ui.callout", "Alert-backed callout composition."),
    entry(.zed_ui, "chip", .stateless_composite, .ui_builder, "Ui.chip", "Badge-backed chip vocabulary."),
    entry(.zed_ui, "collab", .product_composition, .ui_builder, "Ui.row", "Presence/product state remains caller-owned."),
    entry(.zed_ui, "context_menu", .platform_owned, .ui_builder, "Ui.withContextMenu", "Typed items present through the platform menu seam."),
    entry(.zed_ui, "count_badge", .stateless_composite, .ui_builder, "Ui.countBadge", "Formatted count over the badge widget."),
    entry(.zed_ui, "data_table", .stateless_composite, .ui_builder, "Ui.dataTable", "Table shell; data, selection, and sorting remain caller-owned."),
    entry(.zed_ui, "diff_stat", .stateless_composite, .ui_builder, "Ui.diffStat", "Row composition over badges and labels."),
    entry(.zed_ui, "disclosure", .stateless_composite, .ui_builder, "Ui.disclosure", "Accordion/tree disclosure with model-owned expanded state."),
    entry(.zed_ui, "divider", .stateless_composite, .ui_builder, "Ui.divider", "Semantic alias of the separator widget."),
    entry(.zed_ui, "dropdown_menu", .direct_widget, .ui_builder, "Ui.dropdownMenu", "Anchored dismissible menu surface."),
    entry(.zed_ui, "facepile", .stateless_composite, .ui_builder, "Ui.facepile", "Avatar row composition."),
    entry(.zed_ui, "gradient_fade", .algorithm_contract, .canvas_api, "canvas.LinearGradient", "Gradient drawing stays in the canvas paint vocabulary."),
    entry(.zed_ui, "group", .stateless_composite, .ui_builder, "Ui.group", "Accessible caller-owned grouping container."),
    entry(.zed_ui, "icon", .direct_widget, .ui_builder, "Ui.icon", "Compile-checked built-in vector icon."),
    entry(.zed_ui, "image", .direct_widget, .ui_builder, "Ui.image", "Runtime-registered image leaf."),
    entry(.zed_ui, "indent_guides", .runtime_surface, .ui_builder, "Ui.code", "Editor presentation reuses the code surface instead of a second editor state."),
    entry(.zed_ui, "indicator", .stateless_composite, .ui_builder, "Ui.statusIndicator", "Badge-backed status indicator."),
    entry(.zed_ui, "keybinding", .stateless_composite, .ui_builder, "Ui.keybinding", "Compact keyboard-chord label."),
    entry(.zed_ui, "keybinding_hint", .stateless_composite, .ui_builder, "Ui.keybindingHint", "Compact keyboard-chord hint."),
    entry(.zed_ui, "label", .stateless_composite, .ui_builder, "Ui.textLabel", "Semantic text label."),
    entry(.zed_ui, "list", .direct_widget, .ui_builder, "Ui.list", "Retained list and virtual-list foundation."),
    entry(.zed_ui, "modal", .stateless_composite, .ui_builder, "Ui.modal", "Dialog-backed modal with model-owned visibility."),
    entry(.zed_ui, "navigable", .caller_owned, .ui_builder, "Ui.nav", "Navigation index and history remain caller model state."),
    entry(.zed_ui, "notification", .stateless_composite, .ui_builder, "Ui.notification", "Inline notification composition without a global manager."),
    entry(.zed_ui, "popover", .direct_widget, .ui_builder, "Ui.popover", "Anchored popover surface."),
    entry(.zed_ui, "popover_menu", .stateless_composite, .ui_builder, "Ui.popoverMenu", "Popover-menu vocabulary over dropdown menu."),
    entry(.zed_ui, "progress", .direct_widget, .ui_builder, "Ui.progress", "Determinate progress widget."),
    entry(.zed_ui, "project_empty_state", .product_composition, .ui_builder, "Ui.emptyState", "Product copy and actions remain caller composition."),
    entry(.zed_ui, "redistributable_columns", .stateless_composite, .ui_builder, "Ui.redistributableColumns", "Nested split geometry with caller-owned fractions."),
    entry(.zed_ui, "right_click_menu", .platform_owned, .ui_builder, "Ui.rightClickMenu", "Typed context menu over the platform presenter."),
    entry(.zed_ui, "scrollbar", .runtime_surface, .ui_builder, "Ui.scroll", "Scrollbar geometry and physics are runtime-owned."),
    entry(.zed_ui, "stack", .direct_widget, .ui_builder, "Ui.stack", "Retained overlay stack."),
    entry(.zed_ui, "sticky_items", .stateless_composite, .ui_builder, "Ui.stickyItems", "Header remains outside the caller-built scrolling body."),
    entry(.zed_ui, "tab", .stateless_composite, .ui_builder, "Ui.tab", "Button-backed tab semantics with model-owned selection."),
    entry(.zed_ui, "tab_bar", .stateless_composite, .ui_builder, "Ui.tabBar", "Tabs container alias."),
    entry(.zed_ui, "toggle", .direct_widget, .ui_builder, "Ui.toggle", "Model-owned toggle control."),
    entry(.zed_ui, "tooltip", .direct_widget, .ui_builder, "Ui.tooltip", "Runtime-owned hover/focus tooltip timing."),
    entry(.zed_ui, "tree_view_item", .stateless_composite, .ui_builder, "Ui.treeViewItem", "Treeitem semantics over a list row."),

    // gpui-component crates/ui public modules at gpui_component_reference_sha.
    entry(.gpui_component, "accordion", .direct_widget, .ui_builder, "Ui.accordion", "Disclosure surface with caller-owned expanded state."),
    entry(.gpui_component, "alert", .direct_widget, .ui_builder, "Ui.alert", "Native alert surface."),
    entry(.gpui_component, "avatar", .direct_widget, .ui_builder, "Ui.avatar", "Registered image with initials fallback."),
    entry(.gpui_component, "badge", .direct_widget, .ui_builder, "Ui.badge", "Native badge leaf."),
    entry(.gpui_component, "breadcrumb", .direct_widget, .ui_builder, "Ui.breadcrumb", "Breadcrumb row container."),
    entry(.gpui_component, "button", .direct_widget, .ui_builder, "Ui.button", "Native retained button."),
    entry(.gpui_component, "chart", .runtime_surface, .ui_builder, "Ui.chart", "Token-driven deterministic chart surface."),
    entry(.gpui_component, "checkbox", .direct_widget, .ui_builder, "Ui.checkbox", "Model-owned checkbox."),
    entry(.gpui_component, "clipboard", .platform_owned, .platform_api, "platform.PlatformServices.readClipboard", "Clipboard IO stays on the platform/effect seam."),
    entry(.gpui_component, "collapsible", .stateless_composite, .ui_builder, "Ui.collapsible", "Accordion-backed collapsible shell."),
    entry(.gpui_component, "color_picker", .stateless_composite, .ui_builder, "Ui.colorPicker", "Caller-built swatches in a semantic grid."),
    entry(.gpui_component, "combobox", .direct_widget, .ui_builder, "Ui.combobox", "Text entry plus caller-owned suggestion state."),
    entry(.gpui_component, "command", .stateless_composite, .ui_builder, "Ui.commandPalette", "Dialog, search, and results composition; query/selection stay caller-owned."),
    entry(.gpui_component, "description_list", .stateless_composite, .ui_builder, "Ui.descriptionList", "Description rows over the data-grid foundation."),
    entry(.gpui_component, "dialog", .direct_widget, .ui_builder, "Ui.dialog", "Root-relative dialog surface."),
    entry(.gpui_component, "dock", .stateless_composite, .ui_builder, "Ui.dock", "Nested split tree; persistence and tab state remain caller-owned."),
    entry(.gpui_component, "form", .stateless_composite, .ui_builder, "Ui.form", "Accessible field grouping with caller-owned validation state."),
    entry(.gpui_component, "global_state", .caller_owned, .caller_model, "Ui(Msg)", "The caller model is the only application state authority."),
    entry(.gpui_component, "group_box", .stateless_composite, .ui_builder, "Ui.groupBox", "Card-backed grouped content."),
    entry(.gpui_component, "highlighter", .runtime_surface, .ui_builder, "Ui.highlighter", "Syntax highlighting reuses the code surface."),
    entry(.gpui_component, "history", .stateless_composite, .ui_builder, "Ui.history", "List composition over caller-owned history data."),
    entry(.gpui_component, "hover_card", .stateless_composite, .ui_builder, "Ui.hoverCard", "Trigger and anchored content with caller-owned hover intent, delay, and open state."),
    entry(.gpui_component, "input", .direct_widget, .ui_builder, "Ui.input", "Single-line input; number/OTP/search are caller validation compositions."),
    entry(.gpui_component, "kbd", .stateless_composite, .ui_builder, "Ui.kbd", "Compact keyboard-chord badge."),
    entry(.gpui_component, "label", .stateless_composite, .ui_builder, "Ui.textLabel", "Semantic text label."),
    entry(.gpui_component, "link", .stateless_composite, .ui_builder, "Ui.linkButton", "Link semantics over the typed press channel."),
    entry(.gpui_component, "list", .direct_widget, .ui_builder, "Ui.list", "Retained and virtual list foundation."),
    entry(.gpui_component, "menu", .stateless_composite, .ui_builder, "Ui.menu", "Dropdown menu composition."),
    entry(.gpui_component, "native_menu", .platform_owned, .ui_builder, "Ui.nativeMenu", "Typed items present through the native context-menu seam."),
    entry(.gpui_component, "notification", .stateless_composite, .ui_builder, "Ui.notification", "Notification composition without global mutable state."),
    entry(.gpui_component, "pagination", .direct_widget, .ui_builder, "Ui.pagination", "Pagination row container."),
    entry(.gpui_component, "plot", .algorithm_contract, .ui_builder, "Ui.plot", "Chart scales and shapes reuse the deterministic chart pipeline."),
    entry(.gpui_component, "popover", .direct_widget, .ui_builder, "Ui.popover", "Anchored popover surface."),
    entry(.gpui_component, "progress", .direct_widget, .ui_builder, "Ui.progress", "Determinate progress widget."),
    entry(.gpui_component, "radio", .direct_widget, .ui_builder, "Ui.radio", "Model-owned radio control."),
    entry(.gpui_component, "rating", .stateless_composite, .ui_builder, "Ui.rating", "Single-choice shell over caller-built rating items."),
    entry(.gpui_component, "resizable", .direct_widget, .ui_builder, "Ui.resizable", "Resizable panel and split foundations."),
    entry(.gpui_component, "scroll", .runtime_surface, .ui_builder, "Ui.scroll", "Runtime-owned scrolling, physics, and scrollbars."),
    entry(.gpui_component, "searchable_list", .stateless_composite, .ui_builder, "Ui.searchableList", "Search field plus list; filtering and selection stay caller-owned."),
    entry(.gpui_component, "select", .direct_widget, .ui_builder, "Ui.select", "Select trigger plus caller-owned menu state."),
    entry(.gpui_component, "separator", .direct_widget, .ui_builder, "Ui.separator", "Native separator leaf."),
    entry(.gpui_component, "setting", .stateless_composite, .ui_builder, "Ui.setting", "Setting row over caller-owned controls."),
    entry(.gpui_component, "sheet", .direct_widget, .ui_builder, "Ui.sheet", "Root-edge sheet surface."),
    entry(.gpui_component, "sidebar", .stateless_composite, .ui_builder, "Ui.sidebar", "Caller-owned navigation content in a semantic column."),
    entry(.gpui_component, "skeleton", .direct_widget, .ui_builder, "Ui.skeleton", "Loading placeholder leaf."),
    entry(.gpui_component, "slider", .direct_widget, .ui_builder, "Ui.slider", "Model-owned continuous value control."),
    entry(.gpui_component, "spinner", .direct_widget, .ui_builder, "Ui.spinner", "Indeterminate progress leaf."),
    entry(.gpui_component, "status_bar", .direct_widget, .ui_builder, "Ui.statusBar", "Status text leaf."),
    entry(.gpui_component, "stepper", .stateless_composite, .ui_builder, "Ui.stepper", "Model-owned active step over a stateless composite."),
    entry(.gpui_component, "switch", .direct_widget, .ui_builder, "Ui.switchControl", "Model-owned switch control."),
    entry(.gpui_component, "tab", .stateless_composite, .ui_builder, "Ui.tab", "Button-backed tab semantics."),
    entry(.gpui_component, "table", .direct_widget, .ui_builder, "Ui.table", "Table/grid semantics with virtualized row support."),
    entry(.gpui_component, "tag", .stateless_composite, .ui_builder, "Ui.tagBadge", "Badge-backed tag vocabulary."),
    entry(.gpui_component, "text", .direct_widget, .ui_builder, "Ui.text", "Text, paragraph spans, markdown, and selection foundation."),
    entry(.gpui_component, "theme", .caller_owned, .canvas_api, "canvas.DesignTokens", "Themes are immutable token inputs, not global component state."),
    entry(.gpui_component, "tooltip", .direct_widget, .ui_builder, "Ui.tooltip", "Runtime-owned hover/focus tooltip timing."),
    entry(.gpui_component, "tree", .direct_widget, .ui_builder, "Ui.tree", "Tree semantics with model-owned expansion and selection."),
};

fn entry(
    source: ReferenceSource,
    module: []const u8,
    coverage: Coverage,
    entry_point_kind: EntryPointKind,
    native_entry: []const u8,
    note: []const u8,
) Entry {
    return .{
        .source = source,
        .module = module,
        .coverage = coverage,
        .entry_point_kind = entry_point_kind,
        .native_entry = native_entry,
        .note = note,
    };
}

pub fn count(source: ReferenceSource) usize {
    var total: usize = 0;
    for (entries) |item| {
        if (item.source == source) total += 1;
    }
    return total;
}

pub fn find(source: ReferenceSource, module: []const u8) ?*const Entry {
    for (&entries) |*item| {
        if (item.source == source and std.mem.eql(u8, item.module, module)) return item;
    }
    return null;
}

const std = @import("std");
