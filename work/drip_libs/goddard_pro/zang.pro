function zang,dl,z,h,omega                   ;Angular-Diameter Redshift relation
;+
; NAME:
;	ZANG
; PURPOSE:
;	Determine the angular size of an object as a function of redshift
; EXPLANATION:
;	ZANG asumes a Friedmann cosmology (homogeneous, isotropic universe 
;	with zero cosmological constant.
;
; CALLING SEQUENCE:
;	angsiz = zang( dl, [ z, h, omg ] )
;
; INPUTS:
;	dl - linear size of the object in kpc
; OPTIONAL INPUT
;	User will be prompted for these parameters if not supplied.
;
;	z - redshift of object 
;	h - Hubble constant in km/s/Mpc (usually 50 - 100)
;	omega - Cosmological density parameter (twice the deceleration
;		parameter q0), Omega =1 at the critical density
;
; OUTPUT:
;	angsiz - Angular size of the object at the given redshift in 
;		arc seconds 
;
; NOTES:
;	One (and only one) of the input parameters may be supplied as a vector
;	In this case, the output ANGSIZ will also be a vector.
;	Be sure to supply the input linear size dl in units of kpc.
;
; REVISION HISTORY:
;	Written    J. Hill   STX           July, 1988
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 if n_elements(z) lt 1 then read,'Enter redshift of object: ',z
 if n_elements(h) lt 1 then read,'Enter a value for the Hubble constant: ',h
 if n_elements(omega) lt 1 then read, $
     'Enter value of the density parameter (Omega): ',omega

 fac1 = 2.*3.e5/h                                 ;2c/h
 fac2 = 1./(omega^2*(1+z))
 fac3=omega*z-(2.-omega)*(sqrt(1.+omega*z)-1)

 ar = fac1*fac2*fac3                   ;Distance in Mpc to object at redshift z

 return,dl*(1+z)/(1000*ar)*2.062e5

 end
