height=150;
width=150;
depth=100;

wall_width=4;

neck_width=35;
neck_dish_offset=10;

neck_main_slope=60;

dish_height=20;
dish_width=wall_width;

//cube([1,width,height]);


difference() {
    hull() {
    //outter bottom neck
    translate([0,(width-neck_width)/2-wall_width,dish_height+neck_dish_offset]) cube([neck_width+2*wall_width,neck_width+2*wall_width,10]);
    //mid outter
    translate([0,0,dish_height+neck_dish_offset+neck_main_slope]) cube([depth,width,10]);
    //top outter
    translate([0,0,height-10]) cube([depth,width,10]);
    }
    
    hull() {
    //inner bottom neck
    translate([wall_width,(width-neck_width)/2,dish_height+neck_dish_offset]) cube([neck_width,neck_width,10]);
    //mid inner
    translate([wall_width,wall_width,dish_height+neck_dish_offset+neck_main_slope]) cube([depth-2*wall_width,width-2*wall_width,10]);
    //top inner
    translate([wall_width,wall_width,height-10]) cube([depth-2*wall_width,width-2*wall_width,10]);
    }
}

difference() {
union() {
//dish neck drop outter
translate([0,(width-neck_width)/2-wall_width,0]) cube([neck_width+2*wall_width,neck_width+2*wall_width,dish_height+neck_dish_offset]);
translate([-neck_width/2,0,0]) hull() {
    //dish neck drop neck outter
    translate([neck_width+wall_width,(width-neck_width)/2-wall_width,0]) cube([10,neck_width+2*wall_width,dish_height]);
    //dish front 
    translate([depth-wall_width,0,0]) cube([10+wall_width,width,dish_height/2]);
}
}
union() {
//dish neck drop
translate([wall_width,(width-neck_width)/2,dish_width]) cube([neck_width,neck_width,dish_height-dish_width+neck_dish_offset]);
translate([-neck_width/2,0,0]) hull() {
//dish neck drop neck outter
translate([neck_width+wall_width,(width-neck_width)/2,dish_width]) cube([10,neck_width,dish_height-dish_width]);
//dish front 
translate([depth-wall_width,wall_width,dish_width]) cube([10,width-2*wall_width,dish_height-dish_width]);
}
}


}

//the dish
difference() {
    //cube([depth,width,dish_height]);
    //translate([dish_width,dish_width,dish_width]) cube([depth-dish_width*2,width-dish_width*2,dish_height-dish_width]);
}