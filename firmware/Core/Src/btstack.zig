pub const c = @cImport({
    @cInclude("btstack.h");
    @cInclude("gap.h");
});
pub usingnamespace c;
