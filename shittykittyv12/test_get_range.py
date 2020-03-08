a=[47,1,3]
#a=[1,3]
filter(lambda x : x % 2 == 0, a)



def get_spread(a,odd=True,sensors_per_ring=24):
    touched = sorted([ x/2 for x in a if x%2==odd ])
    l=len(touched)
    if l==0:
        return 0
    spreads = [ sensors_per_ring-((touched[(idx+1)%l]-touched[idx])%sensors_per_ring-1) for idx in range(l) ]
    return min(spreads),l

print(get_spread(a,True))
print(get_spread(a,False))
