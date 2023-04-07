const std = @import("std");
const testing = std.testing;

const Color = @import("color.zig").Color;

pub const Address = enum(u8) {
    gateway = 0x0,
    node_1 = 1,
    node_2 = 2,
    node_3 = 3,
    node_4 = 4,
    node_5 = 5,
    node_6 = 6,
    node_7 = 7,
    node_8 = 8,
    node_9 = 9,
    node_10 = 10,
    node_11 = 11,
    node_12 = 12,
    node_13 = 13,
    node_14 = 14,
    node_15 = 15,
    node_16 = 16,
    node_17 = 17,
    node_18 = 18,
    node_19 = 19,
    node_20 = 20,
    node_21 = 21,
    node_22 = 22,
    node_23 = 23,
    node_24 = 24,
    node_25 = 25,
    node_26 = 26,
    node_27 = 27,
    node_28 = 28,
    node_29 = 29,
    node_30 = 30,
    node_31 = 31,
    node_32 = 32,
    node_33 = 33,
    node_34 = 34,
    node_35 = 35,
    node_36 = 36,
    node_37 = 37,
    node_38 = 38,
    node_39 = 39,
    node_40 = 40,
    node_41 = 41,
    node_42 = 42,
    node_43 = 43,
    node_44 = 44,
    node_45 = 45,
    node_46 = 46,
    node_47 = 47,
    node_48 = 48,
    node_49 = 49,
    node_50 = 50,
    node_51 = 51,
    node_52 = 52,
    node_53 = 53,
    node_54 = 54,
    node_55 = 55,
    node_56 = 56,
    node_57 = 57,
    node_58 = 58,
    node_59 = 59,
    node_60 = 60,
    node_61 = 61,
    node_62 = 62,
    node_63 = 63,
    node_64 = 64,
    node_65 = 65,
    node_66 = 66,
    node_67 = 67,
    node_68 = 68,
    node_69 = 69,
    node_70 = 70,
    node_71 = 71,
    node_72 = 72,
    node_73 = 73,
    node_74 = 74,
    node_75 = 75,
    node_76 = 76,
    node_77 = 77,
    node_78 = 78,
    node_79 = 79,
    node_80 = 80,
    node_81 = 81,
    node_82 = 82,
    node_83 = 83,
    node_84 = 84,
    node_85 = 85,
    node_86 = 86,
    node_87 = 87,
    node_88 = 88,
    node_89 = 89,
    node_90 = 90,
    node_91 = 91,
    node_92 = 92,
    node_93 = 93,
    node_94 = 94,
    node_95 = 95,
    node_96 = 96,
    node_97 = 97,
    node_98 = 98,
    node_99 = 99,
    node_100 = 100,
    node_101 = 101,
    node_102 = 102,
    node_103 = 103,
    node_104 = 104,
    node_105 = 105,
    node_106 = 106,
    node_107 = 107,
    node_108 = 108,
    node_109 = 109,
    node_110 = 110,
    node_111 = 111,
    node_112 = 112,
    node_113 = 113,
    node_114 = 114,
    node_115 = 115,
    node_116 = 116,
    node_117 = 117,
    node_118 = 118,
    node_119 = 119,
    node_120 = 120,
    node_121 = 121,
    node_122 = 122,
    node_123 = 123,
    node_124 = 124,
    node_125 = 125,
    node_126 = 126,
    node_127 = 127,
    node_128 = 128,
    node_129 = 129,
    node_130 = 130,
    node_131 = 131,
    node_132 = 132,
    node_133 = 133,
    node_134 = 134,
    node_135 = 135,
    node_136 = 136,
    node_137 = 137,
    node_138 = 138,
    node_139 = 139,
    node_140 = 140,
    node_141 = 141,
    node_142 = 142,
    node_143 = 143,
    node_144 = 144,
    node_145 = 145,
    node_146 = 146,
    node_147 = 147,
    node_148 = 148,
    node_149 = 149,
    node_150 = 150,
    node_151 = 151,
    node_152 = 152,
    node_153 = 153,
    node_154 = 154,
    node_155 = 155,
    node_156 = 156,
    node_157 = 157,
    node_158 = 158,
    node_159 = 159,
    node_160 = 160,
    node_161 = 161,
    node_162 = 162,
    node_163 = 163,
    node_164 = 164,
    node_165 = 165,
    node_166 = 166,
    node_167 = 167,
    node_168 = 168,
    node_169 = 169,
    node_170 = 170,
    node_171 = 171,
    node_172 = 172,
    node_173 = 173,
    node_174 = 174,
    node_175 = 175,
    node_176 = 176,
    node_177 = 177,
    node_178 = 178,
    node_179 = 179,
    node_180 = 180,
    node_181 = 181,
    node_182 = 182,
    node_183 = 183,
    node_184 = 184,
    node_185 = 185,
    node_186 = 186,
    node_187 = 187,
    node_188 = 188,
    node_189 = 189,
    node_190 = 190,
    node_191 = 191,
    node_192 = 192,
    node_193 = 193,
    node_194 = 194,
    node_195 = 195,
    node_196 = 196,
    node_197 = 197,
    node_198 = 198,
    node_199 = 199,
    node_200 = 200,
    node_201 = 201,
    node_202 = 202,
    node_203 = 203,
    node_204 = 204,
    node_205 = 205,
    node_206 = 206,
    node_207 = 207,
    node_208 = 208,
    node_209 = 209,
    node_210 = 210,
    node_211 = 211,
    node_212 = 212,
    node_213 = 213,
    node_214 = 214,
    node_215 = 215,
    node_216 = 216,
    node_217 = 217,
    node_218 = 218,
    node_219 = 219,
    node_220 = 220,
    node_221 = 221,
    node_222 = 222,
    node_223 = 223,
    node_224 = 224,
    node_225 = 225,
    node_226 = 226,
    node_227 = 227,
    node_228 = 228,
    node_229 = 229,
    node_230 = 230,
    node_231 = 231,
    node_232 = 232,
    node_233 = 233,
    node_234 = 234,
    node_235 = 235,
    node_236 = 236,
    node_237 = 237,
    node_238 = 238,
    node_239 = 239,
    node_240 = 240,
    node_241 = 241,
    node_242 = 242,
    node_243 = 243,
    node_244 = 244,
    node_245 = 245,
    node_246 = 246,
    node_247 = 247,
    node_248 = 248,
    node_249 = 249,
    node_250 = 250,
    node_251 = 251,
    node_252 = 252,
    node_253 = 253,
    node_254 = 254,
    broadcast = 255,
};

pub fn Node(comptime T: type) type {
    return struct {
        address: Address,
        network: [16]u8,
        inner: T,
        pub fn init(address: u8, network: [16]u8, inner: T) @This() {
            return .{ .inner = inner, .address = @intToEnum(Address, address), .network = network };
        }
    };
}

pub const Server = Node(struct {});
pub const Client = Node(struct {});

pub const State = enum(u8) { client, server, _ };
pub const Sync = union(State) {
    server: Server,
    client: Client,

    pub const OpCode = enum(u8) { whois, solid, start, stop, fill, _ };
    pub const Patern = enum(u8) { off = 0, rainbow = 1, _ };

    pub const Packet = union(OpCode) {
        whois: Address,
        solid: struct {
            color: Color,
        },
        start: struct { pattern: Patern },
        /// No operand
        stop: @TypeOf(null),
        fill: struct { color: Color, start: u8, end: u8 },
    };

    pub fn handle_packet(self: *const Sync, payload: []u8) ?Packet {
        return switch (self.*) {
            .client => |_| switch (@intToEnum(OpCode, payload[0])) {
                .start => .{ .start = .{ .pattern = @intToEnum(Patern, payload[1]) } },
                .stop => .{ .stop = null },
                .solid => .{ .solid = .{ .color = Color.read_slice(payload[1..]) } },
                .fill => .{ .fill = .{ .color = Color.read_slice(payload[1..]), .start = payload[6], .end = payload[7] } },
                else => null, // unhandled packet from server
            },
            .server => |server| switch (@intToEnum(OpCode, payload[0])) {
                .whois => .{ .whois = server.address },
                else => null, // unhandled packet from client
            },
        };
    }

    test {
        var buffer = try testing.allocator.alloc(u8, 66);
        defer testing.allocator.free(buffer);

        // one server, one client
        const network = "0000000000000001";
        var server: Sync = .{ .server = Server.init(0x69, network.*, .{}) };
        var client: Sync = .{ .client = Client.init(0x10, network.*, .{}) };

        // zero the packet buffer
        std.mem.set(u8, buffer, 0);

        buffer[0] = @enumToInt(OpCode.whois);
        const whois = server.handle_packet(buffer);
        try testing.expectEqual(@as(OpCode, whois.?), OpCode.whois);
        try testing.expectEqual(whois.?.whois, server.server.address);

        std.mem.set(u8, buffer, 0);
        buffer[0] = @enumToInt(OpCode.solid);
        const color = @as(u32, Color.red.raw);
        _ = color;
        Color.red.write_slice(buffer[1..]);
        const solid = client.handle_packet(buffer);
        try testing.expectEqual(@as(OpCode, solid.?), OpCode.solid);
        try testing.expect(solid.?.solid.color.raw == 0xff0000ff);

        std.mem.set(u8, buffer, 0);
        buffer[0] = @enumToInt(OpCode.start);
        buffer[1] = @enumToInt(Patern.rainbow);
        const start = client.handle_packet(buffer);
        try testing.expectEqual(@as(OpCode, start.?), OpCode.start);
        try testing.expectEqual(start.?.start.pattern, .rainbow);

        std.mem.set(u8, buffer, 0);
        buffer[0] = @enumToInt(OpCode.fill);
        Color.blue.write_slice(buffer[1..]);
        buffer[6] = 0x0;
        buffer[7] = 10;
        const fill = client.handle_packet(buffer);
        try testing.expectEqual(@as(OpCode, fill.?), OpCode.fill);
        try testing.expectEqual(fill.?.fill.start, 0);
        try testing.expectEqual(fill.?.fill.end, 10);
        try testing.expect(fill.?.fill.color.raw == Color.blue.raw);
    }
};

test {
    testing.refAllDecls(@This());
}
