
rail_length=220;
rail_thick=3;
rail_depth=15;

carriage_thick=3;
carriage_bowl=110+2.5+2.5;
carriage_slide_width=rail_depth*0.9;
carriage_length=carriage_bowl+carriage_slide_width*2+15-2.5-2.5;
carriage_side=(carriage_length-carriage_bowl)/2;
screw_thick=3;
screw_cap=4;

mount_height=8;

// General Variables
pi = 3.14159;
rad = 57.29578;
clearance = 0.05;   // clearance between teeth

/*  Converts Radians to Degrees */
function grad(pressure_angle) = pressure_angle*rad;

/*  Converts Degrees to Radians */
function radian(pressure_angle) = pressure_angle/rad;


/*  Copy and rotate a Body */
module copier(vect, number, distance, winkel){
    for(i = [0:number-1]){
        translate(v=vect*distance*i)
            rotate(a=i*winkel, v = [0,0,1])
                children(0);
    }
}
/*  Circle Involutes-Function:
    Returns the Polar Coordinates of an Involute Circle
    r = Radius of the Base Circle
    rho = Rolling-angle in Degrees */
function ev(r,rho) = [
    r/cos(rho),
    grad(tan(rho)-radian(rho))
];
/*  Converts 2D Polar Coordinates to Cartesian
    Format: radius, phi; phi = Angle to x-Axis on xy-Plane */
function polar_to_cartesian(polvect) = [
    polvect[0]*cos(polvect[1]),  
    polvect[0]*sin(polvect[1])
];
/*  Spur gear
    modul = Height of the Tooth Tip beyond the Pitch Circle
    tooth_number = Number of Gear Teeth
    width = tooth_width
    bore = Diameter of the Center Hole
    pressure_angle = Pressure Angle, Standard = 20° according to DIN 867. Should not exceed 45°.
    helix_angle = Helix Angle to the Axis of Rotation; 0° = Spur Teeth
    optimized = Create holes for Material-/Weight-Saving or Surface Enhancements where Geometry allows */
module spur_gear(modul, tooth_number, width, bore, pressure_angle = 20, helix_angle = 0, optimized = true) {

    // Dimension Calculations  
    d = modul * tooth_number;                                           // Pitch Circle Diameter
    r = d / 2;                                                      // Pitch Circle Radius
    alpha_spur = atan(tan(pressure_angle)/cos(helix_angle));// Helix Angle in Transverse Section
    db = d * cos(alpha_spur);                                      // Base Circle Diameter
    rb = db / 2;                                                    // Base Circle Radius
    da = (modul <1)? d + modul * 2.2 : d + modul * 2;               // Tip Diameter according to DIN 58400 or DIN 867
    ra = da / 2;                                                    // Tip Circle Radius
    c =  (tooth_number <3)? 0 : modul/6;                                // Tip Clearance
    df = d - 2 * (modul + c);                                       // Root Circle Diameter
    rf = df / 2;                                                    // Root Radius
    rho_ra = acos(rb/ra);                                           // Maximum Rolling Angle;
                                                                    // Involute begins on the Base Circle and ends at the Tip Circle
    rho_r = acos(rb/r);                                             // Rolling Angle at Pitch Circle;
                                                                    // Involute begins on the Base Circle and ends at the Tip Circle
    phi_r = grad(tan(rho_r)-radian(rho_r));                         // Angle to Point of Involute on Pitch Circle
    gamma = rad*width/(r*tan(90-helix_angle));               // Torsion Angle for Extrusion
    step = rho_ra/16;                                            // Involute is divided into 16 pieces
    tau = 360/tooth_number;                                             // Pitch Angle
    
    r_hole = (2*rf - bore)/8;                                    // Radius of Holes for Material-/Weight-Saving
    rm = bore/2+2*r_hole;                                        // Distance of the Axes of the Holes from the Main Axis
    z_hole = floor(2*pi*rm/(3*r_hole));                             // Number of Holes for Material-/Weight-Saving
    
    optimized = (optimized && r >= width*1.5 && d > 2*bore);    // is Optimization useful?

    // Drawing
    union(){
        rotate([0,0,-phi_r-90*(1-clearance)/tooth_number]){                     // Center Tooth on X-Axis;
                                                                        // Makes Alignment with other Gears easier

            linear_extrude(height = width, twist = gamma){
                difference(){
                    union(){
                        tooth_width = (180*(1-clearance))/tooth_number+2*phi_r;
                        circle(rf);                                     // Root Circle 
                        for (rot = [0:tau:360]){
                            rotate (rot){                               // Copy and Rotate "Number of Teeth"
                                polygon(concat(                         // Tooth
                                    [[0,0]],                            // Tooth Segment starts and ends at Origin
                                    [for (rho = [0:step:rho_ra])     // From zero Degrees (Base Circle)
                                                                        // To Maximum Involute Angle (Tip Circle)
                                        polar_to_cartesian(ev(rb,rho))],       // First Involute Flank

                                    [polar_to_cartesian(ev(rb,rho_ra))],       // Point of Involute on Tip Circle

                                    [for (rho = [rho_ra:-step:0])    // of Maximum Involute Angle (Tip Circle)
                                                                        // to zero Degrees (Base Circle)
                                        polar_to_cartesian([ev(rb,rho)[0], tooth_width-ev(rb,rho)[1]])]
                                                                        // Second Involute Flank
                                                                        // (180*(1-clearance)) instead of 180 Degrees,
                                                                        // to allow clearance of the Flanks
                                    )
                                );
                            }
                        }
                    }           
                    circle(r = rm+r_hole*1.49);                         // "bore"
                }
            }
        }
        // with Material Savings
        if (optimized) {
            linear_extrude(height = width){
                difference(){
                        circle(r = (bore+r_hole)/2);
                        circle(r = bore/2);                          // bore
                    }
                }
            linear_extrude(height = (width-r_hole/2 < width*2/3) ? width*2/3 : width-r_hole/2){
                difference(){
                    circle(r=rm+r_hole*1.51);
                    union(){
                        circle(r=(bore+r_hole)/2);
                        for (i = [0:1:z_hole]){
                            translate(sphere_to_cartesian([rm,90,i*360/z_hole]))
                                circle(r = r_hole);
                        }
                    }
                }
            }
        }
        // without Material Savings
        else {
            linear_extrude(height = width){
                difference(){
                    circle(r = rm+r_hole*1.51);
                    circle(r = bore/2);
                }
            }
        }
    }
}
/*  Herringbone; uses the module "spur_gear"
    modul = Height of the Tooth Tip beyond the Pitch Circle
    tooth_number = Number of Gear Teeth
    width = tooth_width
    bore = Diameter of the Center Hole
    pressure_angle = Pressure Angle, Standard = 20° according to DIN 867. Should not exceed 45°.
    helix_angle = Helix Angle to the Axis of Rotation, Standard = 0° (Spur Teeth)
    optimized = Holes for Material-/Weight-Saving */
module herringbone_gear(modul, tooth_number, width, bore, pressure_angle = 20, helix_angle=0, optimized=true){

    width = width/2;
    d = modul * tooth_number;                                           // Pitch Circle Diameter
    r = d / 2;                                                      // Pitch Circle Radius
    c =  (tooth_number <3)? 0 : modul/6;                                // Tip Clearance

    df = d - 2 * (modul + c);                                       // Root Circle Diameter
    rf = df / 2;                                                    // Root Radius

    r_hole = (2*rf - bore)/8;                                    // Radius of Holes for Material-/Weight-Saving
    rm = bore/2+2*r_hole;                                        // Distance of the Axes of the Holes from the Main Axis
    z_hole = floor(2*pi*rm/(3*r_hole));                             // Number of Holes for Material-/Weight-Saving
    
    optimized = (optimized && r >= width*3 && d > 2*bore);      // is Optimization useful?

    translate([0,0,width]){
        union(){
            spur_gear(modul, tooth_number, width, 2*(rm+r_hole*1.49), pressure_angle, helix_angle, false);      // bottom Half
            mirror([0,0,1]){
                spur_gear(modul, tooth_number, width, 2*(rm+r_hole*1.49), pressure_angle, helix_angle, false);  // top Half
            }
        }
    }
    // with Material Savings
    if (optimized) {
        linear_extrude(height = width*2){
            difference(){
                    circle(r = (bore+r_hole)/2);
                    circle(r = bore/2);                          // bore
                }
            }
        linear_extrude(height = (2*width-r_hole/2 < 1.33*width) ? 1.33*width : 2*width-r_hole/2){ //width*4/3
            difference(){
                circle(r=rm+r_hole*1.51);
                union(){
                    circle(r=(bore+r_hole)/2);
                    for (i = [0:1:z_hole]){
                        translate(sphere_to_cartesian([rm,90,i*360/z_hole]))
                            circle(r = r_hole);
                    }
                }
            }
        }
    }
    // without Material Savings
    else {
        linear_extrude(height = width*2){
            difference(){
                circle(r = rm+r_hole*1.51);
                circle(r = bore/2);
            }
        }
    }
}

/*  rack
    modul = Height of the Tooth Tip above the Rolling LIne
    length = Length of the Rack
    height = Height of the Rack to the Pitch Line
    width = Width of a Tooth
    pressure_angle = Pressure Angle, Standard = 20° according to DIN 867. Should not exceed 45°.
    helix_angle = Helix Angle of the Rack Transverse Axis; 0° = Spur Teeth */
module rack(modul, length, height, width, pressure_angle = 20, helix_angle = 0) {

    // Dimension Calculations
    modul=modul*(1-clearance);
    c = modul / 6;                                              // Tip Clearance
    mx = modul/cos(helix_angle);                          // Module Shift by Helix Angle in the X-Direction
    a = 2*mx*tan(pressure_angle)+c*tan(pressure_angle);       // Flank Width
    b = pi*mx/2-2*mx*tan(pressure_angle);                      // Tip Width
    x = width*tan(helix_angle);                          // Topside Shift by Helix Angle in the X-Direction
    nz = ceil((length+abs(2*x))/(pi*mx));                       // Number of Teeth
    
    translate([-pi*mx*(nz-1)/2-a-b/2,-modul,0]){
        intersection(){                                         // Creates a Prism that fits into a Geometric Box
            copier([1,0,0], nz, pi*mx, 0){
                polyhedron(
                    points=[[0,-c,0], [a,2*modul,0], [a+b,2*modul,0], [2*a+b,-c,0], [pi*mx,-c,0], [pi*mx,modul-height,0], [0,modul-height,0], // Underside
                        [0+x,-c,width], [a+x,2*modul,width], [a+b+x,2*modul,width], [2*a+b+x,-c,width], [pi*mx+x,-c,width], [pi*mx+x,modul-height,width], [0+x,modul-height,width]],   // Topside
                    faces=[[6,5,4,3,2,1,0],                     // Underside
                        [1,8,7,0],
                        [9,8,1,2],
                        [10,9,2,3],
                        [11,10,3,4],
                        [12,11,4,5],
                        [13,12,5,6],
                        [7,13,6,0],
                        [7,8,9,10,11,12,13],                    // Topside
                    ]
                );
            };
            translate([abs(x),-height+modul-0.5,-0.5]){
                cube([length,height+modul+1,width+1]);          // Cuboid which includes the Volume of the Rack
            }   
        };
    };  
}


servo_lip_catch=3;
servo_lip_width=3.8;
module carriage() {
    offset=20;
    //translate([carriage_slide_width,-20+offset+servo_lip_width,-servo_h-servo_screw_lip_height-servo_mount_thick-0.25-mount_height]) mirror([1,0,0])  servo_mount_x();
     //translate([carriage_slide_width,-20,-servo_h-servo_screw_lip_height-servo_mount_thick]) mirror([1,0,0])  servo_mount_x();
            //translate([carriage_slide_width,-20+10,-servo_h-servo_screw_lip_height-servo_mount_thick]) mirror([1,0,0])  servo_mount_x();
    intersection() {
        difference() {
            cube([carriage_length,carriage_length,carriage_thick]);
            union() {
                translate([carriage_bowl/2+carriage_side,carriage_bowl/2+carriage_side,-0.5]) cylinder(carriage_thick+1,carriage_bowl/2,carriage_bowl/2);
                translate([carriage_slide_width,-20+offset+servo_lip_width,-servo_h-servo_screw_lip_height-servo_mount_thick-0.25-mount_height]) mirror([1,0,0])  servo_mount_x();
            }
        }
        
        translate([carriage_bowl/2+carriage_side,carriage_bowl/2+carriage_side,-0.5])  union() {
            cylinder(carriage_thick+1,carriage_bowl/2+25,carriage_bowl/2+25);
            translate([-carriage_length/2,-carriage_length/2,-0.5]) cube([carriage_length/2,carriage_length,carriage_thick+2]);
        }
    }
    //translate([carriage_slide_width,-20+offset+servo_lip_width,-servo_h-servo_screw_lip_height-servo_mount_thick-mount_height]) mirror([1,0,0]) servo_mount();
    translate([40,30,carriage_thick]) rotate([180,0,0]) stepper_mount();
}
//servo_mount_x();
module rail(l,teeth=true) {
        difference() {
            difference() {
                //body
                union() {
                    cube([rail_depth+rail_thick,l,rail_thick*2+carriage_thick]);
                    
        rack_height=5;
        teeth_height=2;
        rack_width=rail_depth+rail_thick;
        if (teeth)
        translate([rack_width,l/2,-rail_thick]) rotate([-90,0,90]) rack(modul=teeth_height, length=l, height=rack_height-teeth_height, width=rack_width,   pressure_angle=20, helix_angle=0) ;
                }
                //cutout
                carriage_tolerance=1;
                    translate([-1,-0.5,rail_thick-carriage_tolerance/2]) cube([rail_depth+1,l+1,carriage_thick+carriage_tolerance]);
            }
            
            union() {
                lip=2;
                    //screw
                translate([rail_depth/2,screw_thick+5,-0.5]) cylinder(rail_thick*2+carriage_thick+1,screw_thick,screw_thick);
                translate([rail_depth/2,l-screw_thick-5,-0.5]) cylinder(rail_thick*2+carriage_thick+1,screw_thick,screw_thick);
                    //cap
                translate([rail_depth/2,screw_thick+5,lip-10]) cylinder(rail_thick*2+carriage_thick-lip*2+10,screw_cap,screw_cap);
                translate([rail_depth/2,l-screw_thick-5,lip-10]) cylinder(rail_thick*2+carriage_thick-lip*2+10,screw_cap,screw_cap);
            }
        }
        
}

servo_h=40;
servo_w=20;
servo_d=41;
servo_screw_lip_height=8;
servo_screw_lip_offset=8;
servo_screw_lip_thick=4-0.8;
servo_screw_inner_offset=4;
gear_thick=13;
module servo() {
    difference() {
        union() {
            cube([servo_d,servo_w,servo_h]);
            //9mm offset - spin nipple
            translate([servo_d,servo_w/2,9.5]) rotate([0,90,0]) cylinder(servo_screw_lip_height,6/2,6/2);
            //lip is 8mm and 4mm thick
            translate([servo_d-servo_screw_lip_thick-servo_screw_lip_height,0,-servo_screw_lip_height]) cube([servo_screw_lip_thick,servo_w,servo_h+servo_screw_lip_height*2]);
        }
            
        union() {
            //screws offset 5mm , 5mm thick
            translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-0.5,5,-servo_screw_inner_offset]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+1,5/2,5/2);
            translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-0.5,15,-servo_screw_inner_offset]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+1,5/2,5/2);
            translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-0.5,5,servo_screw_inner_offset+servo_h]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+1,5/2,5/2);
            translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-0.5,15,servo_screw_inner_offset+servo_h]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+1,5/2,5/2);
        }
    }
    
}

servo_mount_thick=8-3;
servo_screw_depth=10;
servo_mount_depth=30;
module servo_mount() {
    translate([-servo_d,0,servo_screw_lip_height+servo_mount_thick]) {
        difference() {
            mount_tol=0.5;
            union() {
                translate([servo_d-servo_mount_depth,-servo_lip_width,servo_h-servo_lip_catch]) cube([servo_mount_depth,servo_w+servo_mount_thick+servo_lip_width,mount_height+servo_lip_catch]);
                translate([servo_d-servo_mount_depth,0,-servo_mount_thick-servo_screw_lip_height]) cube([servo_mount_depth,servo_w+servo_mount_thick,servo_h+carriage_thick+servo_screw_lip_height+servo_mount_thick+mount_height]);
            }

            union() {
                //lip is 8mm and 4mm thick
                    translate([servo_d-servo_screw_lip_thick-mount_tol/2-servo_screw_lip_offset,-1-servo_lip_width,-servo_screw_lip_height]) cube([servo_screw_lip_thick+mount_tol,servo_w+1+servo_lip_width,servo_h+servo_screw_lip_height*2]);
                translate([-0.5,-1,-mount_tol/2]) cube([servo_d+1,servo_w+1,servo_h+mount_tol]);
                
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-servo_screw_depth-0.5,5,-servo_screw_lip_thick-1]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+servo_screw_depth+1,5/2,5/2);
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-servo_screw_depth-0.5,15,-servo_screw_lip_thick-1]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+servo_screw_depth+1,5/2,5/2);
                
                    //translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset,5,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+1,6/2,6/2);
                    //translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset,15,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+1,6/2,6/2);
            }
        }
    }
}


module servo_mount_x() {
    translate([-servo_d,0,servo_screw_lip_height+servo_mount_thick]) {
            mount_tol=0.5;
            union() {
                //lip is 8mm and 4mm thick
                    translate([servo_d-servo_screw_lip_thick-mount_tol/2-servo_screw_lip_offset,-1,-servo_screw_lip_height]) cube([servo_screw_lip_thick+mount_tol,servo_w+1,servo_h+servo_screw_lip_height*2]);
                translate([-0.5,-1,-mount_tol/2]) cube([servo_d+1,servo_w+1,servo_h+mount_tol]);
                
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-servo_screw_depth-0.5,5,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+servo_screw_depth+1,5/2,5/2);
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset-servo_screw_depth-0.5,15,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+servo_screw_depth+1,5/2,5/2);
                
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset,5,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+1,6/2,6/2);
                    translate([servo_d-servo_screw_lip_thick-servo_screw_lip_offset,15,-servo_screw_lip_thick]) rotate([0,90,0]) cylinder(servo_screw_lip_thick+servo_screw_lip_offset+1,6/2,6/2);
            }
        }
}

servo_head_tolerance=0.3;
servo_head_thick=2.5;
servo_head_middle=13+servo_head_tolerance;
servo_head_tail=8+servo_head_tolerance;
servo_head_length=55;
module gear() {
    translate([0,0,gear_thick]) mirror([0,0,1]) difference() {
        //herringbone_gear (modul=2, tooth_number=24, width=gear_thick, bore=10, pressure_angle=20, helix_angle=0, optimized=false);
        herringbone_gear (modul=2, tooth_number=32, width=gear_thick, bore=10, pressure_angle=20, helix_angle=0, optimized=false);
        translate([0,-servo_head_middle/2,servo_head_thick/2]) linear_extrude(height = gear_thick+10.5-9, center = true, convexity = 10, twist = 0) polygon(points=[ [0,0], [-servo_head_length/2,(servo_head_middle-servo_head_tail)/2], [-servo_head_length/2,(servo_head_middle+servo_head_tail)/2], [0,servo_head_middle], [servo_head_length/2,(servo_head_middle+servo_head_tail)/2], [servo_head_length/2,(servo_head_middle-servo_head_tail)/2]]);
    }
}
 

//model
//    color([1,0,0]) translate([servo_d+carriage_slide_width,4,-servo_h]) rotate([0,0,180]) servo();
//color([1,1,1]) translate([carriage_length-carriage_slide_width,0,-rail_thick]) rail(rail_length,false);
//color([1,1,1])translate([carriage_slide_width,rail_length,-rail_thick]) rotate([0,0,180]) rail(rail_length);
//color([0,0,1]) carriage();
//color([0,1,0]) translate([servo_d+carriage_slide_width,4,-servo_h-mount_height]) rotate([0,0,180]) translate([servo_d,servo_w/2,9.5]) rotate([90,0,90]) gear();

//build
rotate([180,0,0]) color([0,0,1]) carriage();
//color([1,1,1]) rotate([0,90,0])  rail(rail_length,false);
//color([1,1,1])  rotate([0,90,0]) rail(rail_length);
//color([0,1,0])  rotate([0,0,0]) gear();
       


motor_width=2;
stepper_d=21;
stepper_h=stepper_d*2;
stepper_w=stepper_d*2;

module stepper_mount() { 
    //translate([stepper_d+motor_width+13.5,-34,0]) {
    translate([0,0,carriage_thick]) {  
        rotate([0,0,90]) {
            difference() {
                difference() {
                    translate([0,0,-carriage_thick]) cube([stepper_w+motor_width*2, stepper_d+motor_width*2,stepper_h/2+motor_width*2+carriage_thick]);
                    translate([motor_width,2,motor_width]) cube([stepper_w, stepper_d+motor_width+0.1 ,stepper_h+10]);
                }
            }
            difference() {
                translate([0,stepper_d+motor_width,0]) cube([stepper_w+motor_width*2,motor_width,motor_width+9]);
                translate([5+motor_width,stepper_d+motor_width*2+0.1,5]) rotate([90,0,0]) cylinder(10,1.5,1.5);
                translate([5+motor_width+stepper_w-10,stepper_d+motor_width*2+0.1,5]) rotate([90,0,0]) cylinder(10,1.5,1.5);
            }
        }
    //}
    }
}