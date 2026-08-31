//! Widget-identity proofs for the ejectable components.
//!
//! `native eject component <name>` copies the canonical sources next to
//! this file into an app. These tests are what keeps those copies
//! honest: each builds the ejected form and the library form against
//! the same inputs and requires the two widget trees to be IDENTICAL —
//! every id, every field, every handler — so ejecting is never a visual
//! or behavioral change, only an ownership change. A library refactor
//! that drifts a composite's tree fails here until the canonical source
//! is updated to match.
//!
//! This file is its own test module (wired in build.zig as
//! `test-eject-components`, part of `zig build test`) because the
//! canonical Zig sources import `native_sdk` exactly as they will
//! inside an app — compiling them verbatim is half the proof.

const std = @import("std");
const testing = std.testing;
const native_sdk = @import("native_sdk");
const canvas = native_sdk.canvas;

const stepper_component = @import("stepper.zig");
const timeline_item_component = @import("timeline_item.zig");
const question_template = @embedFile("question.native");
const timeline_template = @embedFile("timeline.native");
const ui_foundation_template = @embedFile("ui_foundation.native");

/// A stand-in app model/message pair: the composites under test bind no
/// model state themselves (their inputs arrive as options/args), so an
/// empty model and one payload-carrying message tag cover the surface.
const Model = struct {
    one: u32 = 1,
    two: u32 = 2,
    three: u32 = 3,
};
const Msg = union(enum) { open: u32 };
const Ui = canvas.Ui(Msg);

test "ejected stepper builds the library stepper's exact tree" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const labels = [_][]const u8{ "Plan", "Work", "Ship" };
    // Every derived step state in one sweep: active in range (mixed
    // completed/active/pending), zero (nothing completed), and past the
    // end (everything completed).
    for ([_]usize{ 1, 0, labels.len }) |active| {
        var library_ui = Ui.init(arena);
        const library_steps = [_]Ui.StepperStep{
            .{ .label = labels[0] }, .{ .label = labels[1] }, .{ .label = labels[2] },
        };
        const library_tree = try library_ui.finalize(library_ui.stepper(.{ .active = active }, &library_steps));

        var ejected_ui = Ui.init(arena);
        const ejected_steps = [_]stepper_component.Step{
            .{ .label = labels[0] }, .{ .label = labels[1] }, .{ .label = labels[2] },
        };
        const ejected_tree = try ejected_ui.finalize(stepper_component.build(&ejected_ui, .{ .active = active }, &ejected_steps));

        try testing.expectEqualDeep(library_tree.root, ejected_tree.root);
        try testing.expectEqualDeep(library_tree.handlers, ejected_tree.handlers);
    }
}

test "ejected timeline item builds the library item's exact tree, press handler included" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const TimelineItem = timeline_item_component.TimelineItem(Msg);

    // The full shape: indicator variant, description, meta, connector,
    // selection, and a whole-item press (which grows the chevron and
    // binds the handler on the item root).
    var library_ui = Ui.init(arena);
    const library_tree = try library_ui.finalize(library_ui.timelineItem(.{
        .key = .{ .int = 7 },
        .icon = "check",
        .variant = .primary,
        .title = "Build the release",
        .description = "Compile, test, and package the app",
        .meta = "2m 14s",
        .selected = true,
        .on_press = .{ .open = 7 },
    }));

    var ejected_ui = Ui.init(arena);
    const ejected_tree = try ejected_ui.finalize(TimelineItem.build(&ejected_ui, .{
        .key = .{ .int = 7 },
        .icon = "check",
        .variant = .primary,
        .title = "Build the release",
        .description = "Compile, test, and package the app",
        .meta = "2m 14s",
        .selected = true,
        .on_press = .{ .open = 7 },
    }));

    try testing.expectEqualDeep(library_tree.root, ejected_tree.root);
    try testing.expectEqualDeep(library_tree.handlers, ejected_tree.handlers);
    // The press is real in both forms, not just structurally equal.
    try testing.expectEqual(Msg{ .open = 7 }, ejected_tree.msgForPointer(ejected_tree.root.id, .up).?);

    // The minimal shape: dot indicator (no badge content), title only,
    // no connector, no press — the other half of every conditional.
    var minimal_library_ui = Ui.init(arena);
    const minimal_library = try minimal_library_ui.finalize(minimal_library_ui.timelineItem(.{
        .title = "Queued",
        .connector = false,
    }));
    var minimal_ejected_ui = Ui.init(arena);
    const minimal_ejected = try minimal_ejected_ui.finalize(TimelineItem.build(&minimal_ejected_ui, .{
        .title = "Queued",
        .connector = false,
    }));
    try testing.expectEqualDeep(minimal_library.root, minimal_ejected.root);
    try testing.expectEqualDeep(minimal_library.handlers, minimal_ejected.handlers);
}

/// Build a markup view over the test Model through the interpreter,
/// resolving imports from an embedded source set (the same loader shape
/// apps use for their import closures).
fn buildMarkupTree(arena: std.mem.Allocator, ui: *Ui, root_source: []const u8, files: []const canvas.ui_markup.SourceFile) !Ui.Tree {
    var set_loader = canvas.ui_markup.SourceSetLoader{ .set = files };
    var diagnostic: canvas.ui_markup.MarkupErrorInfo = .{};
    const document = canvas.ui_markup.resolveImports(arena, "app.native", root_source, set_loader.loader(), &diagnostic) catch |err| {
        std.debug.print("markup resolve failed: {s} ({s}:{d}:{d})\n", .{ diagnostic.message, diagnostic.path, diagnostic.line, diagnostic.column });
        return err;
    };
    var interpreter = canvas.MarkupView(Model, Msg).fromDocument(try canvas.ui_markup.canonicalize(arena, document));
    var model = Model{};
    return ui.finalize(try interpreter.build(ui, &model));
}

test "the ejected timeline template builds the library <timeline> element's exact tree" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Identical item children on both sides; only the container differs:
    // the built-in element versus the ejected template reached through
    // <use> (which inlines its body, so ids hash as if written in place).
    const items =
        \\  <timeline-item title="Cloned" description="Fetched the sources" icon="check" variant="primary" />
        \\  <timeline-item title="Building" meta="just now" connector="false" />
        \\
    ;
    const element_source = "<timeline gap=\"4\" label=\"Activity\">\n" ++ items ++ "</timeline>\n";
    const template_source = "<import src=\"components/timeline.native\"/>\n" ++
        "<use template=\"timeline\" gap=\"4\" label=\"Activity\">\n" ++ items ++ "</use>\n";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/timeline.native", .source = timeline_template },
    };

    var element_ui = Ui.init(arena);
    const element_tree = try buildMarkupTree(arena, &element_ui, element_source, &files);
    var template_ui = Ui.init(arena);
    const template_tree = try buildMarkupTree(arena, &template_ui, template_source, &files);

    try testing.expectEqualDeep(element_tree.root, template_tree.root);
    try testing.expectEqualDeep(element_tree.handlers.len, template_tree.handlers.len);
    // Spot-check the facts the deep compare rests on: the container is
    // the list-role column the library builds, at the declared gap.
    try testing.expectEqual(canvas.WidgetKind.column, template_tree.root.kind);
    try testing.expectEqual(canvas.WidgetRole.list, template_tree.root.semantics.role);
    try testing.expectEqual(@as(f32, 4), template_tree.root.layout.gap);
    try testing.expectEqualStrings("Activity", template_tree.root.semantics.label);
    try testing.expectEqual(@as(usize, 2), template_tree.root.children.len);
}

test "the ejected timeline template's defaults match the library element's defaults" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const items = "<timeline-item title=\"Only\" connector=\"false\" />";
    const element_source = "<timeline>" ++ items ++ "</timeline>";
    const template_source = "<import src=\"components/timeline.native\"/>\n" ++
        "<use template=\"timeline\">" ++ items ++ "</use>";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/timeline.native", .source = timeline_template },
    };

    var element_ui = Ui.init(arena);
    const element_tree = try buildMarkupTree(arena, &element_ui, element_source, &files);
    var template_ui = Ui.init(arena);
    const template_tree = try buildMarkupTree(arena, &template_ui, template_source, &files);

    try testing.expectEqualDeep(element_tree.root, template_tree.root);
}

test "the public UI foundation templates are headless and resolve through the real import path" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const source =
        "<import src=\"components/ui_foundation.native\"/>\n" ++
        "<column>\n" ++
        "  <use template=\"ui-foundation-toolbar\" label=\"Toolbar\" globalkey=\"toolbar\" windowdrag=\"true\"><text>Title</text></use>\n" ++
        "  <use template=\"ui-foundation-sidebar\" label=\"Sidebar\" globalkey=\"sidebar\"><text>Nav</text></use>\n" ++
        "  <use template=\"ui-foundation-composer\" label=\"Composer\"><textarea label=\"Composer\" /></use>\n" ++
        "  <use template=\"ui-foundation-panel\" label=\"Panel\"><text>Body</text></use>\n" ++
        "  <use template=\"ui-foundation-timeline\" label=\"Activity\"><text>Item</text></use>\n" ++
        "</column>\n";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/ui_foundation.native", .source = ui_foundation_template },
    };
    var ui = Ui.init(arena);
    const tree = try buildMarkupTree(arena, &ui, source, &files);
    try testing.expectEqual(canvas.WidgetKind.column, tree.root.kind);
    try testing.expectEqual(@as(usize, 5), tree.root.children.len);
    try testing.expectEqual(canvas.WidgetKind.row, tree.root.children[0].kind);
    try testing.expectEqual(canvas.WidgetKind.column, tree.root.children[1].kind);
    try testing.expectEqual(canvas.WidgetKind.row, tree.root.children[2].kind);
    try testing.expectEqual(@as(f32, 0), tree.root.children[2].layout.grow);
    try testing.expectEqual(canvas.WidgetKind.panel, tree.root.children[3].kind);
    try testing.expectEqual(canvas.WidgetKind.column, tree.root.children[4].kind);
}

test "the ejected question templates build the library question composition's exact tree" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const source =
        "<import src=\"components/question.native\"/>\n" ++
        "<use template=\"question-frame\" label=\"Deployment target\" width=\"420\">\n" ++
        "  <use template=\"question-header\" prompt=\"Where should we deploy?\" description=\"Choose one region or add context.\" />\n" ++
        "  <use template=\"question-single-options\" label=\"Deployment region\">\n" ++
        "    <radio checked=\"true\" on-change=\"open:{one}\">Washington, D.C.</radio>\n" ++
        "    <radio on-change=\"open:{two}\">San Francisco</radio>\n" ++
        "  </use>\n" ++
        "  <textarea label=\"Additional context\" placeholder=\"Optional details\" />\n" ++
        "  <use template=\"question-actions\"><button variant=\"primary\" on-press=\"open:{three}\">Answer</button></use>\n" ++
        "</use>\n";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/question.native", .source = question_template },
    };

    var template_ui = Ui.init(arena);
    const template_tree = try buildMarkupTree(arena, &template_ui, source, &files);

    var library_ui = Ui.init(arena);
    const library_tree = try library_ui.finalize(library_ui.questionFrame(.{
        .label = "Deployment target",
        .width = 420,
    }, .{
        library_ui.questionHeader("Where should we deploy?", "Choose one region or add context."),
        library_ui.questionSingleOptions(.{ .label = "Deployment region" }, .{
            library_ui.radio(.{ .text = "Washington, D.C.", .checked = true, .on_change = .{ .open = 1 } }),
            library_ui.radio(.{ .text = "San Francisco", .on_change = .{ .open = 2 } }),
        }),
        library_ui.textarea(.{ .placeholder = "Optional details", .semantics = .{ .label = "Additional context" } }),
        library_ui.questionActions(.{}, .{
            library_ui.button(.{ .variant = .primary, .on_press = .{ .open = 3 } }, "Answer"),
        }),
    }));

    try testing.expectEqualDeep(library_tree.root, template_tree.root);
    try testing.expectEqualDeep(library_tree.handlers, template_tree.handlers);
    try testing.expectEqual(canvas.WidgetKind.card, template_tree.root.kind);
    try testing.expectEqual(canvas.WidgetRole.group, template_tree.root.semantics.role);
    try testing.expectEqualStrings("Deployment target", template_tree.root.semantics.label);
    try testing.expectEqual(@as(usize, 1), template_tree.root.children.len);
    const content = template_tree.root.children[0];
    try testing.expectEqual(@as(usize, 4), content.children.len);
    try testing.expectEqual(canvas.WidgetRole.radiogroup, content.children[1].semantics.role);
    try testing.expectEqual(Msg{ .open = 2 }, template_tree.msgFor(content.children[1].children[1].id, .change).?);
    try testing.expectEqual(Msg{ .open = 3 }, template_tree.msgForPointer(content.children[3].children[0].id, .up).?);
}

test "the question templates preserve default frame spacing and an optional description" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const source =
        "<import src=\"components/question.native\"/>\n" ++
        "<use template=\"question-frame\" label=\"Confirmation\">\n" ++
        "  <use template=\"question-header\" prompt=\"Proceed?\" />\n" ++
        "</use>\n";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/question.native", .source = question_template },
    };

    var template_ui = Ui.init(arena);
    const template_tree = try buildMarkupTree(arena, &template_ui, source, &files);
    var library_ui = Ui.init(arena);
    const library_tree = try library_ui.finalize(library_ui.questionFrame(.{ .label = "Confirmation" }, .{
        library_ui.questionHeader("Proceed?", ""),
    }));

    try testing.expectEqualDeep(library_tree.root, template_tree.root);
    try testing.expectEqual(@as(f32, 16), template_tree.root.layout.padding.top);
    try testing.expectEqual(@as(f32, 0), template_tree.root.layout.min_size.width);
    try testing.expectEqual(@as(f32, 0), template_tree.root.layout.max_size.width);
    try testing.expectEqual(@as(f32, 0), template_tree.root.layout.grow);
    const content = template_tree.root.children[0];
    try testing.expectEqual(@as(f32, 12), content.layout.gap);
    try testing.expectEqual(@as(usize, 1), content.children[0].children.len);
}

test "the question multiple-options template preserves checkbox semantics and caller messages" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const source =
        "<import src=\"components/question.native\"/>\n" ++
        "<use template=\"question-multiple-options\" label=\"Project features\" gap=\"10\">\n" ++
        "  <checkbox checked=\"true\" on-toggle=\"open:{one}\">Authentication</checkbox>\n" ++
        "  <checkbox on-toggle=\"open:{two}\">Payments</checkbox>\n" ++
        "</use>\n";
    const files = [_]canvas.ui_markup.SourceFile{
        .{ .path = "components/question.native", .source = question_template },
    };

    var template_ui = Ui.init(arena);
    const template_tree = try buildMarkupTree(arena, &template_ui, source, &files);

    var library_ui = Ui.init(arena);
    const library_tree = try library_ui.finalize(library_ui.questionMultipleOptions(.{
        .label = "Project features",
        .gap = 10,
    }, .{
        library_ui.checkbox(.{ .text = "Authentication", .checked = true, .on_toggle = .{ .open = 1 } }),
        library_ui.checkbox(.{ .text = "Payments", .on_toggle = .{ .open = 2 } }),
    }));

    try testing.expectEqualDeep(library_tree.root, template_tree.root);
    try testing.expectEqualDeep(library_tree.handlers, template_tree.handlers);
    try testing.expectEqual(canvas.WidgetRole.group, template_tree.root.semantics.role);
    try testing.expectEqualStrings("Project features", template_tree.root.semantics.label);
    try testing.expectEqual(canvas.WidgetKind.checkbox, template_tree.root.children[0].kind);
    try testing.expectEqual(Msg{ .open = 2 }, template_tree.msgForPointer(template_tree.root.children[1].id, .up).?);
}
