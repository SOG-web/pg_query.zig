const root = @import("../root.zig");
pub const NodeKind = root.NodeKind;
pub const NodeRef = root.NodeRef;
pub const Context = root.Context;
pub const generated_node_ref = root.generated_node_ref;
pub const generated_node_mut = root.generated_node_mut;
pub const generated_walk_exhaustive = root.generated_walk_exhaustive;

// Compatibility surface: these remain public because protocol code depends on them today.
pub fn nodeKind(node: *const root.pb.Node) ?NodeKind {
    return root.nodeKind(node);
}

pub fn nodeToRef(node: *const root.pb.Node) ?root.generated_node_ref.NodeRef {
    return root.nodeToRef(node);
}

pub fn nodeToMut(node: *root.pb.Node) ?root.generated_node_mut.NodeMut {
    return root.nodeToMut(node);
}
