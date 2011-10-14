pro backfit, file, outfile, BLSIZE=blsize, SMSIZE=smsize

if not(keyword_set(BLSIZE)) then blsize = 10
if not(keyword_set(SMSIZE)) then smsize = 10

im     = file ;readfits(file,h)

; Fit the background

imfilt = fiterpolate(im,blsize,blsize)

; Smooth the result

imsmoo = smooth(imfilt,smsize)

; Subtract the background

imout  = im - imsmoo

atv22, imout
outfile = imout
;writefits, outfile, imout, h

end 

