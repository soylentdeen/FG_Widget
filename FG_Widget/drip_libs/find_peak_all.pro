;This program calculates centroids of the four brightest peaks in 'image'

;Distance formula between 2 points.

function findDist, x, y, xcen, ycen
    d = (((x-xcen)^2) + ((y-ycen)^2))^(0.5)
    return, d
end 


;Averages the color density of a 3 by 3 pixel.

function avgCells, arr, m, n
   t = arr(m-1,n+1)+arr(m,n+1)+arr(m+1,n+1)+arr(m-1,n)+arr(m,n)+arr(m+1,n)+arr(m-1,n-1)+arr(m,n-1)+arr(m+1,n-1)
   t = t/9
   return, t
end


;Returns the x and y coordinates of where the color density within a certain radius is greatest.

function fits,img

;scans each pixel and finds the one with the maximum intensity

   imgSize = SIZE(img)
   imgSize = imgSize[2]

   bright = -1
   x = -1
   y = -1
   t = 0
   
   ;Change the border to exclude bad pixels
   border = 6
   for i = border, imgSize-border do begin
      for j = border, imgSize-border do begin      
         t = avgCells(img, i, j)
         if t gt bright then begin
            bright = t
            x = i
            y = j
         endif
      endfor
    endfor
    hm = (0.5)*t

    flag = 1
    k = 1

    while flag do begin
        t1 = avgCells(img, (x-k), y)
        if t1 gt hm then begin
           x1 = (x-k)
           y1 = y
           flag = 0
        endif
        k = k + 1
    endwhile
    
    flag = 1
    k = 1
    while flag do begin
        t2 = avgCells(img, (x+k), y)
        if t2 gt hm then begin
           x2 = (x+k)
           y2 = y
           flag = 0
        endif
        k = k + 1
    endwhile
    
    flag = 1
    k = 1
    while flag do begin
        t3 = avgCells(img, x, (y-k))
        if t3 gt hm then begin
           x3 = x
           y3 = y-k
           flag = 0
        endif
        k = k + 1
    endwhile     

    flag = 1
    k = 1
    while flag do begin
        t4 = avgCells(img, x, (y+k))
        if t4 gt hm then begin
           x4 = x
           y4 = y+k
           flag = 0
        endif
        k = k + 1
    endwhile 

    flag = 1
    k = 1
    while flag do begin
        t5 = avgCells(img, (x+k), (y+k))
        if t5 gt hm then begin
           x5 = x+k
           y5 = y+k
           flag = 0
        endif
        k = k + 1
    endwhile 

    flag = 1
    k = 1
    while flag do begin
        t6 = avgCells(img, (x+k), (y-k))
        if t6 gt hm then begin
           x6 = x+k
           y6 = y-k
           flag = 0
        endif
        k = k + 1
    endwhile 

    flag = 1

    k = 1
    while flag do begin
        t7 = avgCells(img, (x-k), (y+k))
        if t7 gt hm then begin
           x7 = x-k
           y7 = y+k
           flag = 0
        endif
        k = k + 1
    endwhile 

    flag = 1
    k = 1
    while flag do begin
        t8 = avgCells(img, (x-k), (y-k))
        if t8 gt hm then begin
           x8 = x-k
           y8 = y-k
           flag = 0
        endif
        k = k + 1
    endwhile

   d1 = findDist(x1,y1,x,y)
   d2 = findDist(x2,y2,x,y)

   d3 = findDist(x3,y3,x,y)
   d4 = findDist(x4,y4,x,y)
   d5 = findDist(x5,y5,x,y)
   d6 = findDist(x6,y6,x,y)
   d7 = findDist(x7,y7,x,y)
   d8 = findDist(x8,y8,x,y)
   r = [d1, d2, d3, d4, d5, d6, d7, d8]
   r = max(r)   

   return, [x, y, r]

end

function find_peak_all,img

; Check that img is valid, return if not
; 

; Add new argument, NUM_PEAK, the number of peaks to find. This will
; be set by the INSTMODE before the call to find_peak_all
; C2N : find 4 peaks
; C2  : find 2 peaks
; STARE: find 1 peak


;img=img[*,0:254]
imgSize = SIZE(img)
length = imgSize(2)
arr = abs(img)
second_image = arr   ; Absolute value of image for centroid
second_img =img      ; Original image (for coadding later)



k=0
xFinal=[0,0,0,0]
yFinal=[0,0,0,0]
x=[-100,-100,-100,-100]
y=[-100,-100,-100,-100]
r=[0,0,0,0]

while k lt 4 do begin
   t = fits(arr)
   x[k] = t[0]
   y[k] = t[1]
   for i=0, length-1 do begin
      for j=0, length-1 do begin
         d = findDist(i,j,t[0],t[1])
         rr = t[2]
         if d lt 20*rr then begin
            arr(i,j) = -1
         endif
      endfor
    endfor
    k = k + 1
endwhile

k=0

distances = [0,0,0,0]
center = length/2

while k lt 4 do begin
   imcentroid, second_image, xcen, ycen, x[k], y[k]
   xFinal[k] = xcen
   yFinal[k] = ycen
   distances[k] = findDist(center, center, xFinal[k], yFinal[k])

   k = k + 1
endwhile

center_source = where(distances eq min(distances))

origin = second_image
origin_img = second_img

third = second_image
third_img = second_img

fourth = second_image
fourth_img = second_img

;If 2 or more sources tie for the center_source, then it picks the first one...

size = SIZE(center_source)
size = size[2]

if size ne 1 then begin
   center_source = center_source[0]
endif 

; Merge original frames

j=0
while j lt 3 do begin
   if center_source eq 0 then begin
      if j eq 0 then begin  
         origin = origin + shift(second_image, xFinal[0]-xFinal[1], yFinal[0]-yFinal[1])
      endif else if j eq 1 then begin
         origin = origin + shift(third, xFinal[0]-xFinal[2], yFinal[0]-yFinal[2])
      endif else if j eq 2 then begin
         origin = origin + shift(fourth, xFinal[0]-xFinal[3], yFinal[0]-yFinal[3])
      endif
   endif else if center_source eq 1 then begin
      if j eq 0 then begin  
         origin = origin + shift(second_image, xFinal[1]-xFinal[0], yFinal[1]-yFinal[0])
      endif else if j eq 1 then begin
         origin = origin + shift(third, xFinal[1]-xFinal[2], yFinal[1]-yFinal[2])
      endif else if j eq 2 then begin
         origin = origin + shift(fourth, xFinal[1]-xFinal[3], yFinal[1]-yFinal[3])
      endif
   endif else if center_source eq 2 then begin  
      if j eq 0 then begin  
         origin = origin + shift(second_image, xFinal[2]-xFinal[0], yFinal[2]-yFinal[0])
      endif else if j eq 1 then begin
         origin = origin + shift(third, xFinal[2]-xFinal[1], yFinal[2]-yFinal[1])
      endif else if j eq 2 then begin
         origin = origin + shift(fourth, xFinal[2]-xFinal[3], yFinal[2]-yFinal[3])
      endif
   endif else if center_source eq 3 then begin 
      if j eq 0 then begin  
         origin = origin + shift(second_image, xFinal[3]-xFinal[0], yFinal[3]-yFinal[0])
      endif else if j eq 1 then begin
         origin = origin + shift(third, xFinal[3]-xFinal[1], yFinal[3]-yFinal[1])
      endif else if j eq 2 then begin
         origin = origin + shift(fourth, xFinal[3]-xFinal[2], yFinal[3]-yFinal[2])
      endif
   endif
   j = j + 1
endwhile
print,'xFinal:  ',xFinal
return, origin

end
