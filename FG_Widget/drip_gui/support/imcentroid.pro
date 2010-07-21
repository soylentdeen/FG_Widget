pro imcentroid, main_image, xcen, ycen, x, y

; program to calculate the center of mass of an image around
; the point (x,y), return the answer in (xcen,ycen).
;
; by M. Liu, adapted for inclusion in ATV by AJB
; Adapted to stand alone by L. Keller 6/3/2010
;
; ALGORITHM:
;   1. first finds max pixel value in
;    a 'bigbox' box around the cursor
;   2. then calculates centroid around the object 
;   3. iterates, recalculating the center of mass 
;      around centroid until the shifts become smaller 
;      than MINSHIFT (0.3 pixels)

; iteration controls
MINSHIFT = 0.3

; max possible x or y direction shift
MAXSHIFT = 15

boxsize = 25
; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
bigbox=round(1.5*boxsize)

sz = size(main_image)

; box size must be odd
dc = (boxsize-1)/2
if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
db = (bigbox-1)/2

; need to start with integers
xx = x
yy = y

; make sure there aren't NaN values in the apertures.
;minx = 0 > (xx - state.outersky)  
;maxx = (xx + state.outersky) < (state.image_size[0] - 1)
;miny = 0 > (yy - state.outersky)  
;maxy = (yy + state.outersky) < (state.image_size[1] - 1)

;subimg = main_image[minx:maxx, miny:maxy]
;if (finite(mean(subimg)) EQ 0) then begin
;    xcen = xx
;    ycen = yy
;    state.photwarning = 'WARNING: Region contains NaN values.'
;    return
;endif

; first find max pixel in box around the cursor
x0 = (xx-db) > 0
x1 = (xx+db) < (sz(1)-1)
y0 = (yy-db) > 0
y1 = (yy+db) < (sz(2)-1)
cut = main_image[x0:x1,y0:y1]
cutmax = max(cut)
w=where(cut EQ cutmax)
cutsize = size(cut)
my = (floor(w/cutsize[1]))[0]
mx = (w - my*cutsize[1])[0]

xx = mx + x0
yy = my + y0 
xcen = xx
ycen = yy

; then find centroid 
if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen)) 
    yy = round(total(ycen)/n_elements(ycen)) 
endif

done = 0
niter = 1
    
; cut out relevant portion
sz = size(main_image)
x0 = round((xx-dc) > 0)   ; need the ()'s
x1 = round((xx+dc) < (sz[1]-1))
y0 = round((yy-dc) > 0)
y1 = round((yy+dc) < (sz[2]-1))
xs = x1 - x0 + 1
ys = y1 - y0 + 1
cut = float(main_image[x0:x1, y0:y1])

; sky subtract before centering
; note that this is a quick and dirty solution, and may cause
; centering problems for poorly behaved data  -- AB, 2/28/07
;cut = cut - min(cut)
                                ; find x position of center of mass
cenxx = fltarr(xs, ys, /nozero)
for i = 0L, (xs-1) do $         ; column loop
  cenxx[i, *] = cut[i, *] * i
xcen = total(cenxx) / total(cut) + x0

                                ; find y position of center of mass
cenyy = fltarr(xs, ys, /nozero)
for i = 0L, (ys-1) do $         ; row loop
  cenyy[*, i] = cut[*, i] * i
ycen = total(cenyy) / total(cut) + y0

if (abs(xcen-x) gt MAXSHIFT) or $
  (abs(ycen-y) gt MAXSHIFT) then begin
    print,'Warning: Possible mis-centering?'
endif

; add final check for xcen, ycen = NaN: this can happen if the region
; contains all negative values
if (finite(xcen) EQ 0 OR finite(ycen) EQ 0) then begin
    print,'Warning: Unable to center.'
    xcen = x
    ycen = y
endif

end