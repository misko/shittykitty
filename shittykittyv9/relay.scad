
thick=10;
w=27;
l=34;
tol=0.3;
difference() {
    difference() { 
        union() { 
            translate([-thick/2,-thick/2,-thick*1.5]) cube([w+thick,l+thick,15+thick*1.5]);
            translate([-thick/2-thick*2,-thick/2,-thick*1.5]) cube([w+thick*5,l+thick,10]);
        }
        x=2;
        translate([x,x,-20]) cylinder(40,1,1);
        translate([w-x,x,-20]) cylinder(40,1,1);
        translate([x,l-x,-20]) cylinder(40,1,1);
        translate([w-x,l-x,-20]) cylinder(40,1,1);
        
        
        translate([-thick*1.5,l/2,-20]) cylinder(40,2.5,2.5);
        translate([w+thick*1.5,l/2,-20]) cylinder(40,2.5,2.5);
    }
    
    union() {
        translate([-tol/2,-tol/2,0]) cube([w+tol,l+tol,20]);
        translate([2.5,-10,0]) cube([w-5,l+20,30]);
    }
}