;This function produces a coadded image from the .fits files specified
;in the files input variable, using the findpeaks program. Files
;should be a 1-D array of filepaths.  The savepath input variable
;specifies where the fits file of the co-added image will be saved.  


function shiftpeaks, files ;, savepath

filelist = fltarr(256,256,n_elements(files))

filelist[*,*,0] = readfits(files[0], header)


for i = 1,n_elements(files) - 1 do begin

filelist[*,*,i]= readfits(files[i])

endfor


s = size(filelist)

coords = fltarr(2,s[3])


for i = 0,s[3]-1 do begin

x = findpeaks(filelist[*,*,i])

coords[0,i] = x[0]
coords[1,i] = x[1]

endfor


img = filelist[*,*,0]

move = fltarr(2)


for i = 1, s[3]-1 do begin

move = coords[*,0]-coords[*,i]

img = img + shift(filelist[*,*,i],move)
print, move
endfor


img = img/s[3]

atv22, img
atvplot, move[0], move[1], psym=4
;writefits, savepath, img, header


return, img

end





