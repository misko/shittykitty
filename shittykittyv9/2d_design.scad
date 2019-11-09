

module band(r1,r2) {
    difference() {
        circle(r2);
        circle(r1);
    }
}

module get_slice(r1,r2, angle) {
    difference() {
        band(r1,r2);
        union() {
            rotate([0,0,-(90-angle)]) translate([-r2,0,0]) square([3*r2,3*r2]);
            translate([-3*r2,-1.5*r2,0]) square([3*r2,3*r2]);
        }
    }
}

color([1,0,0]) get_slice(5,20,45);
//color([0,1,0]) get_slice(10,12,45);