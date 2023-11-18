const std = @import("std");
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
pub inline fn vec(f: f32) Vec3 { return @splat(f); }

pub const Color = struct {
    const black : Vec3 = [_]f32{0.0, 0.0, 0.0};
    const white : Vec3 = [_]f32{1.0, 1.0, 1.0};
    const red   : Vec3 = [_]f32{1.0, 0.0, 0.0};
    const green : Vec3 = [_]f32{0.0, 1.0, 0.0};
    const blue  : Vec3 = [_]f32{0.0, 0.0, 1.0};
};

const X = 0;
const Y = 1;
const Z = 2;

const U = 0;
const V = 1;

const R = 0;
const G = 1;
const B = 2;

const tile_height = 2000;
const tile_width = 2000;

const tiles_count_height = 4;
const tiles_count_width = 4;

const screen_height = tile_height * tiles_count_height;
const screen_width = tile_width * tiles_count_width;

var screen: [screen_height * screen_width * 3]u8 = undefined;



//triangle frag
pub fn frag(pos: Vec2, mask: u4) Vec3 { //recive x, y -- returns rgb
    //@setFloatMode(.Optimized);
    const colors = [_]Vec3{
    (Color.red + Color.green),
    (Color.red) 
    };

    const centers: [4]Vec2 = [_]Vec2 {
    [_]f32{0.0,0.5}, //left
    [_]f32{0.5,0.0}, //top
    [_]f32{1.0,0.5}, //right
    [_]f32{0.5,1.0}  //botton
    };

    const d = 0.5;
    const d_diff = 0.5 / d;
    const sides_dist: [2]Vec2 = [_]Vec2 {
    [_]f32{d, d*d_diff}, //horizontal increase Y
    [_]f32{d*d_diff, d}  //vertiacal increase X
    };

    inline for (centers, 0..) |c,i| {
        const m = (mask >> i) & 1;
        var p = pos;
        p -= c;
        p = @fabs(p);

        //normalizing with ratio
        var max_distance = sides_dist[i%2];
        p /= max_distance;

        const n_dist = @reduce(.Add, p);

        //painting if in range
        if (n_dist < 1){
            const sin = 1 - (@sin(n_dist * (std.math.pi / 2.0)));
            const gradient = vec(sin);
            return colors[m] * gradient;
        }
    }
    return Color.black; 
    //return Color.white * vec(0.8);

}

pub fn drawFile(file_path: []const u8) !void{
    const file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    // writting the P6 header
    const bitmap_file_header = try std.fmt.allocPrint(fba.allocator(), "P6\n{d} {d}\n255\n", .{screen_height, screen_width});
    _ = try file.write(bitmap_file_header);

    // writing white color

    var cursor: usize = 0;

    for(0..screen_height) |row| {
        for(0..screen_width) |col| {
            // normalizing from 0.0 to 1.0
            const y = row % tile_height;
            const x = col % tile_width;
            const xf = @as(f32, @floatFromInt(x)) / tile_width;
            const yf = @as(f32, @floatFromInt(y)) / tile_height;

            // getting to the fake fragment shader
            var rgb = frag(.{xf,yf}, @as(u4, @truncate((row / tile_height) * tiles_count_width  + col / tile_width)));

            // mapping it back the color definition
            rgb *= @splat(255);
            screen[cursor] = @intFromFloat(rgb[R]);
            cursor += 1;
            screen[cursor] = @intFromFloat(rgb[G]);
            cursor += 1;
            screen[cursor] = @intFromFloat(rgb[B]);
            cursor += 1;
        }
    }
    _= try file.write(&screen);
}
pub fn main() !void {
    var buf = [_]u8{'0', '.', 'p', 'p', 'm'};
    std.debug.print("stating...\n", .{});

    try drawFile(&buf);
    std.debug.print("end...\n", .{});

}


