pro testinterp,eps=eps
;INPUT: jup.fits 	2-D image data array
;       mask.fits	2-D mask array
;OUTPUT: fixed image data arrays
;	testplinterp.fits     (plane surface fit)
;	testginterp.fits      (2-D guassain surface fit)
;	testcsplinterp.fits   (bicubic spline interpolation)	
;	testsplinterp.fits    (bicubic spline interpolation)
;	testchebyinterp.fits  (Chebyshev polynomial interpolation)
;	testtwoordinterp.fits (Second order polynomial interpolation)
if not(keyword_defined(eps)) then eps = 1e-7
;Read in .fits files
raw = readfits('jup.fits')
mask = readfits('mask.fits')
;Plane surface fit
g = maskinterp(raw,mask,1,6,"plsfit") 
writefits,'testplinterp.fits',g
;2-D guassian surface fit
g = maskinterp(raw,mask,1,6,"gausfit") 
writefits,'testginterp.fits',g
;bicubic spline interpolation
g = maskinterp(raw,mask,1,6,"csplinterp") 
writefits,'testcsplinterp.fits',g
;bicubic spline interpolation
g = maskinterp(raw,mask,1,6,"splinterp") 
writefits,'testsplinterp.fits',g
;Chebyshev polynomial interpolation
g = maskinterp(raw,mask,1,6,"chebyshfit") 
writefits,'testchebyinterp.fits',g
g = maskinterp(raw,mask,1,6,"twoordfit")
writefits,'testtwoordinterp.fits',g
;Compare the given files to the generated files
filecomp,'testplinterp0.fits','testplinterp.fits',eps
filecomp,'testginterp0.fits','testginterp.fits',eps
filecomp,'testcsplinterp0.fits','testcsplinterp.fits',eps
filecomp,'testsplinterp0.fits','testsplinterp.fits',eps
filecomp,'testchebyinterp0.fits','testchebyinterp.fits',eps
filecomp,'testtwoordinterp0.fits','testtwoordinterp.fits',eps
end
