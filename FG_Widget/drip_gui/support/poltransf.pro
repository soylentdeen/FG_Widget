pro poltransf, im1, im2, outfile

aconv = 180.0/!pi

i = readfits(im1,hi)
j = readfits(im2,hj)

i = unsharp_mask(i,RADIUS=5)
j = unsharp_mask(j,RADIUS=5)

i = i - median(i)
j = j - median(j)

isz = size(i)
jsz = size(j)

print, isz[1],isz[2]
print, jsz[1],jsz[2]

nix = isz[1]
niy = isz[2]
ixc = isz[1]/2
iyc = isz[2]/2

njx = jsz[1]
njy = jsz[2]
jxc = jsz[1]/2
jyc = jsz[2]/2

ri = fltarr(nix,niy)
ai = fltarr(nix,niy)
riarr = fltarr(nix*niy)
aiarr = fltarr(nix*niy)
iarr = fltarr(nix*niy)

rj = fltarr(njx,njy)
aj = fltarr(njx,njy)
rjarr = fltarr(njx*njy)
ajarr = fltarr(njx*njy)
jarr = fltarr(njx*njy)

for k=0,nix-1 do begin
    for l=0,niy-1 do begin
        ri[k,l] = sqrt((k-ixc)^2 + (l-iyc)^2)
        ai[k,l] = atan((l-iyc),(k-ixc)) * aconv  
        indx    = k*niy + l
        riarr[indx] = ri[k,l]
        aiarr[indx] = ai[k,l]
        iarr[indx] = i[k,l]
    endfor
endfor

for k=0,njx-1 do begin
    for l=0,njy-1 do begin
        rj[k,l] = sqrt((k-jxc)^2 + (l-jyc)^2)
        aj[k,l] = atan((l-jyc),(k-jxc)) * aconv   
        indx    = k*njy + l
        rjarr[indx] = rj[k,l]
        ajarr[indx] = aj[k,l]
        jarr[indx] = j[k,l]
    endfor
endfor

;irz = where(riarr le 0.0)
;riarr[irz] = 1.0e-5
;riarr = alog(riarr)
;jrz = where(rjarr le 0.0)
;rjarr[jrz] = 1.0e-5
;rjarr = alog(rjarr)

iz = where(aiarr lt 0.0)
aiarr[iz] = 360.0 + aiarr[iz]
jz = where(ajarr lt 0.0)
ajarr[jz] = 360.0 + ajarr[jz]

rmax = max([max(riarr),max(rjarr)])
print, rmax

triangulate, riarr, aiarr, tri
triangulate, rjarr, ajarr, trj

lims = [0.,0.,rmax,360.0]
afact=0.5
rfact=0.5
;rfact=0.01
na   = round(360.0/afact) - 1
nr   = round(rmax/rfact) - 1

;ip = trigrid(riarr,aiarr,iarr,tri,[rfact,afact],NX=nr,NY=na,MISSING=0)
;jp = trigrid(rjarr,ajarr,jarr,trj,[rfact,afact],NX=nr,NY=na,MISSING=0)
ip = trigrid(riarr,aiarr,iarr,tri,[rfact,afact],lims,MISSING=0)
jp = trigrid(rjarr,ajarr,jarr,trj,[rfact,afact],lims,MISSING=0)

ip = unsharp_mask(ip,RADIUS=5)
jp = unsharp_mask(jp,RADIUS=5)

correl_optimize, ip, jp, ropt, aopt
print, ropt, aopt

;cmat = correl_images(ip,jp,xshift=0,yshift=45)
;corrmat_analyze,cmat,ropt,aopt
;print, ropt, aopt

arot = -1.0*aopt*afact 
print, arot

jrot = rot(j,arot,1.0,jxc,jyc,/INTERP,MISSING=0.0)
atv, jrot
writefits, outfile, jrot, hj

end
