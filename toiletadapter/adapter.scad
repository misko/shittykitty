
/*
cup_top_radius=46;
cup_bottom_radius=32;
cup_height=114;	
cup_lip=3;	
cup_lip_height=1.5;
cup_radius=cup_top_radius+cup_lip;
s_l=30.5;
s_h=30.5;
s_w=13.5;
s_o=0;
s_r=5;
s_p=7; //offset of pivot point in servo
s_ph=s_p; //servo pivot height

screw_r=2;

horn_r1=2.7;
horn_r2=4.6;
horn_c=2.5;
horn_height=5;
horn_arm=15;*/

cup_top_radius=56;
cup_bottom_radius=32;
cup_height=114;	
cup_lip=3;	
cup_lip_height=0.5;
cup_radius=cup_top_radius+cup_lip;
s_l=24.5;
s_h=30.5;
s_w=13.5;
s_o=0;
s_r=5;
s_p=7; //offset of pivot point in servo
s_ph=s_p; //servo pivot height

screw_r=3;

horn_r1=2;
horn_r2=3.9;
horn_c=2.5;
horn_height=5;
horn_arm=13.5;

module servo() {
    color("black") {
        translate([-s_p,-s_w/2,-s_h-s_ph]) { 
            cube([s_l,s_w,s_h]);
            translate([s_p,s_w/2,s_h]) cylinder(h=s_ph,r1=s_r,r2=s_r);
        }
    }
}

module horn() {
	translate([0,0,-horn_height+horn_c]) {
        hull() {
            translate([-horn_arm-3,0,0]) cylinder(h=horn_height-horn_c,r1=horn_r1,r2=horn_r1);
            translate([horn_arm+3,0,0]) cylinder(h=horn_height-horn_c,r1=horn_r1,r2=horn_r1);
            cylinder(h=horn_height-horn_c,r1=horn_r2,r2=horn_r2);
        }
	}
	translate([0,0,-horn_height]) cylinder(h=horn_height,r1=horn_r2,r2=horn_r2);
}


module ir_sensor_mount() {
ir_spacing=36;
ir_width=8;
ir_height=35;
difference() {
        union() {
            translate([-ir_height+10,-ir_spacing/2-ir_width,0]) cube([ir_height,ir_spacing+2*ir_width,10]);
            translate([-ir_height+10,-ir_spacing/2-ir_width,-ir_width*2]) cube([10,ir_spacing+2*ir_width,ir_width*2]);
        }
        union() {
            translate([0,ir_spacing/2,-1]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
            translate([0,-ir_spacing/2,-1]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
            //wire spacing
            translate([-ir_height+10,0,-20]) cylinder(h=50,r1=13,r2=13);
            //anchors to toilet
            translate([-40,20,-ir_width]) rotate([0,90,0]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
            translate([-40,-20,-ir_width]) rotate([0,90,0]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
        }
}
}

module servo_clamp(clamp_height=15,clamp_width=10) {
    wiggle=3;
    difference() {
        difference() {
            color("thistle") {
                translate([-s_p-clamp_width,-s_w/2,-s_h/2-s_ph-clamp_height/2]) { 
                    translate([0,20+7,clamp_height-wiggle]) cube([s_l+clamp_width*2,s_w+clamp_width-5,clamp_height+cup_lip_height+wiggle]);
                    translate([0,0,4]) cube([s_l+clamp_width*2,s_w+clamp_width+30-8,clamp_height-wiggle-4]);
                }
            }
            servo();
        }
        union () {
            translate([-s_p-clamp_width+10,-s_w/2+36,-s_h/2-s_ph-clamp_height/2-1]) cylinder(h=50,r1=screw_r,r2=screw_r);
            translate([-s_p-clamp_width+10,-s_w/2+36,-s_h/2-s_ph-clamp_height/2-1-25]) cylinder(h=50,r1=screw_r+2,r2=screw_r+2); //bigger hole
            translate([-s_p-clamp_width+(s_l+clamp_width*2)-10,-s_w/2+36,-s_h/2-s_ph-clamp_height/2-1]) cylinder(h=50,r1=screw_r,r2=screw_r);
            translate([-s_p-clamp_width+(s_l+clamp_width*2)-10,-s_w/2+36,-s_h/2-s_ph-clamp_height/2-1-25]) cylinder(h=50,r1=screw_r+2,r2=screw_r+2);
            translate([-s_p-clamp_width+10-2,0,-s_h/2-s_ph-clamp_height/2-1]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
            translate([-s_p-clamp_width+(s_l+clamp_width*2)-10+2,0,-s_h/2-s_ph-clamp_height/2-1]) cylinder(h=50,r1=screw_r-1,r2=screw_r-1);
        }
    }
}

module cup() {
        union() {
            color("red") {
                translate([0,0,-cup_height-cup_lip_height]) {
                        cylinder(h = cup_height, r1 = cup_bottom_radius, r2 = cup_top_radius);
                }
            }   
            color("white") {
                translate([0,0,-cup_lip_height]) cylinder(h = cup_lip_height, r1 = cup_top_radius+cup_lip, r2 = cup_top_radius+cup_lip);
            }
        }   
}


module cup_holder(width=5,nipple=15) {
    color("blue") {
	difference() {
		union() {
			difference() {
				translate([-horn_arm,-horn_r2/2-5,-horn_height]) cube([(horn_arm+5)*2,horn_r2+10,horn_height]);
				horn();
			}
			difference() {
				hull() {
					translate([horn_arm+5+horn_r1+cup_radius,0,0]) {
						translate([0,0,-5]) cylinder(h=5,r1=cup_top_radius+width,r2=cup_top_radius+width);
					}
					//the servo square
					translate([-horn_arm,-horn_r2/2-5,-horn_height]) cube([(horn_arm+5)*2,horn_r2+10,horn_height]);
					//nipple on far side
					translate([horn_arm+5+horn_r1+cup_radius+cup_top_radius,0,-5]) cube([nipple,10,5]);
				}
				//the servo square
				translate([-horn_arm,-horn_r2/2-5,-horn_height]) cube([(horn_arm+5)*2,horn_r2+10,horn_height]);
			} 
		}
        translate([horn_arm+5+horn_r1+cup_radius,0,0]) translate([0,0,-cup_height+cup_lip_height]) cylinder(h=cup_height,r1=cup_top_radius+1.5,r2=cup_top_radius+1.5);
		//translate([(sqrt(2))*cup_radius,0,0]) translate([0,0,cup_lip_height]) cup();
	}
}
	
}


outter_orbit_radius=(1+sqrt(2))*cup_radius;
inner_orbit_radius=(sqrt(2)-1)*cup_radius;
module orbit(radiusx=5) {
	intersection() {
		difference() {
			difference() {
				cylinder(h=5,r1=radiusx+1,r2=radiusx+1);
				translate([-radiusx,0,0]) cube([2*radiusx+1,radiusx+1,5]);
			}
			{
				translate([0,0,-1]) cylinder(h=5+2,r1=radiusx-1,r2=radiusx-1);
			}
		}
		rotate([0,0,-135]) cube([radiusx+10,radiusx+10,5]);
	}
}
//orbit(outter_orbit_radius);
//orbit(inner_orbit_radius);


module rail(rail_height=5,inner_r=10,outter_r=20) {
        color("Teal") {
		difference() {
			difference() {
				cylinder(h=rail_height,r1=outter_r,r2=outter_r);
				translate([-outter_r,0,-1]) cube([2*outter_r,outter_r,rail_height+2]);
			}
			{
				translate([0,0,-1]) cylinder(h=rail_height+2,r1=inner_r,r2=inner_r);
			}
		}
    }
}



module seat() {
    translate([0,0,-20]) {
        difference() {
            scale([1,2/3,1]) scale([1.5,1.5,1]) cylinder(h=20,r1=300,r2=300);
            scale([1,2/3,1]) translate([0,0,-1]) cylinder(h=22,r1=300,r2=300);
        }
    }
}

module cover() {
    difference() {
        scale([1,2/3,1]) scale([1.5,1.5,1]) cylinder(h=20,r1=300,r2=300);
        translate([-cup_radius,-cup_radius,-1]) {
            cylinder(h=22,r1=cup_radius,r2=cup_radius);
        }
    }
}



rotate([0,0,0]) {
    translate([-450,0,0]) {
        //%cover();
        //stepper
        //rotate([0,-90,0]) ir_sensor_mount();
        rotate([0,0,0]) { 
            //servo();
            //servo_clamp();
        }
        echo($t/100);
        
        //rotate([0,0,(-$t*90)]) {
        rotate([0,0,(-70)]) {
            rotate([0,0,-45]) {
                //cup_holder(width=8,nipple=15);
            }
            translate([0,-cup_radius,0]){
                //translate([cup_radius,0,cup_lip]) cup();
            }
        }
        
        //outter rail
offset=12;
        //bottom rail part
        
        screwA=5;
        screwB=-87;
        difference() {
            union() {
                translate([0,0,-5-5]) rail(rail_height=5,inner_r=cup_top_radius+sqrt(2)*cup_radius,outter_r=cup_top_radius+sqrt(2)*cup_radius+25);
            }
            union() {
                rotate([0,0,screwA]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10]) cylinder(h=5+cup_lip_height+1.3+5,r1=screw_r,r2=screw_r);
                rotate([0,0,screwB]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10]) cylinder(h=5+cup_lip_height+1.3+5,r1=screw_r,r2=screw_r);
                    rotate([0,0,0]) translate([20,-(cup_top_radius+sqrt(2)*cup_radius+offset)-20,-11]) cube([1000,1000,1000]);
            }
        }
        //screw tops
        difference() {
            union() {
                    rotate([0,0,screwA]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10+5]) cylinder(h=5+cup_lip_height+1.3,r1=screw_r+5,r2=screw_r+5);
                    rotate([0,0,screwB]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10+5]) cylinder(h=5+cup_lip_height+1.3,r1=screw_r+5,r2=screw_r+5);
            }
            union() {
                rotate([0,0,screwA]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10+5]) cylinder(h=5+cup_lip_height+1.3,r1=screw_r,r2=screw_r);
                rotate([0,0,screwB]) translate([0,-(cup_top_radius+sqrt(2)*cup_radius+offset),-10+5]) cylinder(h=5+cup_lip_height+1.3,r1=screw_r,r2=screw_r);
            }
        }
        
   }
}
    translate([-450,0,0]) {
        //%seat();
        
    }
