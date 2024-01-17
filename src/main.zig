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

const tile_height = 200;
const tile_width  = 200;

//size in tiles
const screen_height_tl = 4;
const screen_width_tl  = 4;

// //size in pixels
const screen_height_px = tile_height * screen_height_tl;
const screen_width_px  = tile_width  * screen_width_tl;

//the generated wang tiles map
var grid: [screen_height_tl][screen_width_tl]u4 = undefined;

var screen: [screen_height_px][screen_width_px][3]u8 = undefined;
var screen_slice: []u8 = @as([*]u8, @ptrCast(&screen))[0..@sizeOf(@TypeOf(screen))];


//triangle frag
pub fn frag(pos: Vec2, color_mask: u4) Vec3 { //recive x, y -- returns rgb
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

    const d = 0.45;
    const d_diff = 0.5 / d;
    const sides_dist: [2]Vec2 = [_]Vec2 {
    [_]f32{d, d*d_diff}, //horizontal increase Y
    [_]f32{d*d_diff, d}  //vertiacal increase X
    };

    inline for (centers, 0..) |c,i| {
        const m = (color_mask >> i) & 1;
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
    for (&grid, 0..) |*row,y| {
        for (row, 0..) |*mask,x| {
            if(y == 0) {
                if(x == 0) {
                    mask.* = generateRandTile(0,0);
                }
                else {
                    mask.* = generateRandTile(grid[0][x-1] & 0b0100, 0b0100);
                }
                continue;
            }
            if(x == 0) {
                mask.* = generateRandTile(grid[y-1][0] & 0b1000, 0b1000);
            }
            else {
                mask.* = generateRandTile((grid[y-1][x] & 0b1000) | (grid[y][x-1] & 0b0100), 0b1100);
            }
        }
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

    for(&screen, 0..) |*row, s_y| {
        for(&row.*, 0..) |*col, s_x| {
            const tl_x = s_x / tile_width;
            const tl_y = s_y / tile_height;

            const px_x = s_x % tile_width;
            const px_y = s_y % tile_height;

            const x: f32 = @as(f32, @floatFromInt(px_x))/tile_width;
            const y: f32 = @as(f32, @floatFromInt(px_y))/tile_height;

            var rgb = frag(.{x, y}, grid[tl_y][tl_x]);

            rgb *= @splat(255);
            col[R] = @intFromFloat(rgb[R]);
            col[G] = @intFromFloat(rgb[G]);
            col[B] = @intFromFloat(rgb[B]);
        }
    }
    _= try file.write(screen_slice);
}
pub fn main() !void {
    var file_name = "output.ppm";
    std.debug.print("stating...\n", .{});

    generateGrid();

    try drawImageToFile(file_name);

    std.debug.print("end...\n", .{});

}


