const std = @import("std");
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);

pub const Color = struct {
    const black : Vec3 = [_]f32{0.0, 0.0, 0.0};
    const white : Vec3 = [_]f32{1.0, 1.0, 1.0};
    const red   : Vec3 = [_]f32{1.0, 0.0, 0.0};
    const green : Vec3 = [_]f32{0.0, 1.0, 0.0};
    const blue  : Vec3 = [_]f32{0.0, 0.0, 1.0};
};

const R = 0;
const G = 1;
const B = 2;

const tile_height = 100;
const tile_width  = 100;

//size in tiles
const screen_height_tl = 50;
const screen_width_tl  = 50;

//size in pixels
const screen_height_px = tile_height * screen_height_tl;
const screen_width_px  = tile_width  * screen_width_tl;

//size in bytes
const screen_height_bt = screen_height_px * 3; 
const screen_width_bt  = screen_width_px  * 3;

var screen: [screen_height_bt * screen_width_bt]u8 = undefined;

//the generated wang tiles map
var grid: [screen_height_tl * screen_width_tl]u4 = undefined;



//triangle frag
pub fn frag(pos: Vec2, mask: u4) Vec3 { //recive x, y -- returns rgb
    //@setFloatMode(.Optimized);

    //puts black square in the middle
    // const mid_dist = @fabs(pos - @as(Vec2, @splat(0.5)));
    // if(mid_dist[0] < 0.3 and mid_dist[1] < 0.3) return Color.black;

    const colors = [_]Vec3{
    (Color.red + Color.blue),
    (Color.red) 
    };

    //mask
    //0b0011 -- top left
    //0b1100 -- bot right
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
            //harder sin gradiant
            // const sin = 1 - (@sin(n_dist * (std.math.pi / 2.0)));
            // const gradient: Vec3 = @splat(sin);

            //softer sin gradiant
            // const sin = 1 - (@sin(n_dist * (1.0 / 2.0) / @sin(1 * (1.0 / 2.0))));
            // const gradient: Vec3 = @splat(sin);

            //cos function gradiant
            // const cos = (@cos(n_dist * (std.math.pi / 2.0)));
            // const gradient: Vec3 = @splat(cos);

            //raw gradient
            const gradient: Vec3 = @splat(0.7);

            return colors[m] * gradient;
        }
    }
    return Color.black; 

}

var randomizer: std.rand.DefaultPrng = undefined;
pub fn generateRandTile(values_mask: u4, pos_mask :u4) u4{

    const rand_num = randomizer.random().int(u4);//@as(u4, @truncate(@as(u128, std.time.nanoTimestamp()))); //time

    //0b1100 -- bot right
    //0b0011 -- top left
    return (rand_num & (~(pos_mask >> 2))) | ((values_mask >> 2));
}
pub fn generateGrid() void {
    randomizer = std.rand.DefaultPrng.init(@bitCast(std.time.milliTimestamp()));

    //0b1100 -- bot right
    //0b0011 -- top left
    for (&grid, 0..) |*mask,i| {
        mask.* = switch(i) {
            0 => generateRandTile(0,0),

            1...screen_width_tl - 1 => generateRandTile(grid[i-1] & 0b0100, 0b0100),

            else => blk: {

                const y = (i / screen_width_tl);
                const raw_y = (y * screen_width_tl);
                const x = i - raw_y;

                break: blk if (i % screen_width_tl == 0)
                    generateRandTile(grid[raw_y - screen_width_tl + x] & 0b1000 ,
                                                                         0b1000)
                else 
                    generateRandTile((grid[raw_y - screen_width_tl + x] & 0b1000) |
                                          (grid[raw_y + x - 1] & 0b0100), 0b1100);
               
            },
        };
    }

}
pub fn drawImageToFile(file_path: []const u8) !void{
    const file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    var buffer: [100]u8 = undefined;

    // writting the P6 header
    const bitmap_file_header = try std.fmt.bufPrint( &buffer,
                                                     "P6\n{d} {d}\n255\n",
                                                     .{
                                                         screen_width_px,
                                                         screen_height_px
                                                     });
    _ = try file.write(bitmap_file_header);

    var cursor: usize = 0;

    for(0..screen_height_px) |row| {
         for(0..screen_width_px) |col| {
            // normalizing from 0.0 to 1.0
            const y = row % tile_height;
            const x = col % tile_width;
            const xf = @as(f32, @floatFromInt(x)) / tile_width;
            const yf = @as(f32, @floatFromInt(y)) / tile_height;

            // getting to the fake fragment shader
            const pos = (((row/tile_height) * screen_width_tl) + (col/tile_width));
            var rgb = frag(.{xf,yf}, grid[pos]);

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
    var file_name = "output.ppm";
    std.debug.print("stating...\n", .{});

    generateGrid();

    try drawImageToFile(file_name);

    std.debug.print("end...\n", .{});

}


