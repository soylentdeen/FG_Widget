; NAME:
;     DRIP_MERGE - Version .7.0
;
; PURPOSE:
;     Coadd different images
;
; CALLING SEQUENCE:
;     MERGED=DRIP_MERGE(DATA, HEADER)
;
; INPUTS:
;     DATA - Data to be merged i.e. frame with target images
;     HEADER - The fits header of the new input data file
;
; OUTPUTS:
;     MERGED - The merged image
;              i.e. frame with images of object at chop and not positions
;              merged
;
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS:
;     None.
;
; PROCEDURE:
;     add each frame of the data to a 2-d summation frame,
;     in a manner appropriate to the current reduction scheme,
;     then average by the number of frames
;
; MODIFICATION HISTORY:
;   Written by:  Alfred Lee, Cornell University, 2001
;   Modified:    Alfred Lee, Cornell University, February, 2002
;                 made function aware of caller, to run the appropriate
;                 algorithm without keywords.  removed header search.
;                 updated 2-position chop co-add algorithm.
;     Modified:   Alfred Lee, CU, June 6, 2002
;                 changed into an object.  added MODE parameter.
;     Modified:   Alfred Lee, CU, June 18, 2002
;                 switched TPCON code to TPCOFF, added TPCON code.
;     Modified:   Alfred Lee, CU, June 20, 2002
;                 added findchop and findnod methods.
;     Modified:   Alfred Lee, CU, June 24, 2002
;                 Created RUN method to run the code as needed after a single
;                 initialization.  adjusted TPC on chip co-adding algorithm.
;     Modified:   Alfred Lee, CU, July 18, 2002
;                 enhanced error checking
;     Modified:   Alfred Lee, CU, August 5, 2002
;                 Converted from MAKE_IMAGE
;     Modified:   Alfred Lee, CU, August 26, 2002
;                 Updated for use with MPC.
;     Modified:   Alfred Lee, CU September 23, 2002
;                 Updated TPC code to work with proposed CHOP and NOD keywords.
;                 Starting with algorithms for MPC
;     Modified:   Alfred Lee, CU, September 26, 2002
;                 Finished MPC algorithms.
;     Modified:   Alfred Lee, CU, November 20, 2002
;                 changed angles to radians.
;     Modified:   Marc Berthoud, CU, October 20, 2003
;                 added MPC and updated TPC merge
;     Rewritten:  Marc Berthoud, CU, July 2004
;                 Rewrote from object to one-line command
;                 Most code erased (see merge_define v.5.4)
;     Modified:   Marc Berthoud, CU, November 2004
;                 Changed case into switch to have TPCD and C3PD
;     Modified:   Marc Berthoud, CU, February 2005
;                 Added test mode
;     Modified:   Marc Berthoud, CU, March 2005
;                 Renamed all modes
;     Modified:   Marc Berthoud, CU, May 2006
;                 Added stack coadding before merging
;     Modified:   Marc Berthoud, Palomar, July 2006
;                 Added output for intermediate steps
;                 (chopsub, nodframes, nodsub)
;     Modified:   Marc Berthoud, CU, August 2007
;                 Added choping with voltages, nodding with RA, DEC
;     Modified:   Luke Keller and Marc Berthoud, Ithaca College March 2010
;                 Added optioon to shift and add by pixe
;                 specified with TELESCOP='PIXELS'. Added check for
;                 off-chip nodding.
;     Modified:   Luke Keller, Ithaca College, and Bill Vacca, USRA May 2010
;                 Incorporated cross-correlation of chop/nod pairs for locating
;                 and registering images for merge and coadd
;     Modified:   Marc Berthoud, Ithaca College, July 2010
;                 - Added use of resize and border variables
;                 - FOR C2N ONLY: optimized improvement of nod/chop
;                   x/y with correlation
;     Modified:   Luke Keller, Ithaca College, June 2011
;                 Added Nod-match-chop mode
;


;******************************************************************************
;     DRIP_MERGE - Merges object images
;******************************************************************************

function drip_merge, data, flatted, header

; error check
s=size(data)
;print,'MERGE SIZE',size(data)
if s[0] ne 2 then begin
    drip_message, 'drip_merge - Must provide valid new data array',/fatal
    return, data
endif
hs=size(header)
if (hs[0] ne 1) or (hs[2] ne 7) then drip_message, $
  'drip_merge - invalid header'

;**** merge
; initialize variables
resize=2.0 ;2.0
border=128 ;128
merged=fltarr(s[1],s[2])
mode=drip_getpar(header,'INSTMODE')
telescope=drip_getpar(header,'TELESCOP') ; to determine plate scale
plate_scale=0.77  ; assume telescope = SOFIA, then plate scale is 0.77 arcsec/pixel
x_plate_scale=0.77
y_plate_scale=0.77
if telescope eq 'Palomar' then plate_scale=7.274 ; pixels per volt
if telescope eq 'PIXELS' then plate_scale=1.0 ; keep chop and nod ampitudes in pixels
mode=strtrim(mode,2)

; run appropriate method
switch mode of
    'C2': begin ; 2 position chop
        ; get chop distances
        chpcoordsys=drip_getpar(header,'CHPCOORD') ; Get chop coord system: 0=SIRF, 1=TARF, 2=ERF
        sky_angle=float(drip_getpar(header,'SKY_ANGL'))*!pi/180.0
        chopdist=float(drip_getpar(header,'CHPAMP1')*2) ; *2 MCCS sends champ1/2, [was /plate_scale] 
        chopang=float(drip_getpar(header,'CHPANGLE'))
        chopdist=float(chopdist)
        chopang=!pi/180*chopang
        chopx=chopdist*sin(chopang)/x_plate_scale
        chopy=chopdist*cos(chopang)/y_plate_scale
        ;chopx=chopdist*sin(chopang)
        ;chopy=chopdist*cos(chopang)  ; was -
        ; multiply by resize due to supersampling in undistort
        chopx=chopx  ;*=resize
        chopy=chopy  ;*=resize
        
        if (chpcoordsys eq 2) then begin
          erf_chopx = (chopx*cos(sky_angle) + chopy*sin(sky_angle))
          erf_chopy = (chopy*cos(sky_angle) - chopx*sin(sky_angle))
          chopx = erf_chopx
          chopy = erf_chopy
        endif
        
        ;if (sqrt(chopx^2+chopy^2)) lt resize*128 then begin
 
        ; CORREL_OPTIMIZE TEST **********
        cormerge=drip_getpar(header,'CORMERGE') ; Keyword replace flag for merge method:
                                               ; CORMERGE = 'COR' then use
                                               ; cross-correlation
                                               ; CORMERGE = 'CENT' then use centroid
                                               ; CORMERGE = 'N' then use
                                               ; nominal nod and chop positions
        if cormerge eq 'CORFLT' then begin
            drip_message,'drip_merge - Using cross-correlation to merge chop/nod frames'
            cordata = flatted[*,0:254,*]  ; Use flatfielded data (no undistort, no stack)
                                          ; 0:254 gets rid of funky top row (artifact of fft clean process)
            cordata=data
            s = size(cordata)
            cormerged=fltarr(s[1],s[2])
            ; CORREL_OPTIMIZE **********
            ; First make difference image of all chop/nod pairs and their
            ; inverses
            im0 = cordata[*,*,0]
            im1 = cordata[*,*,1]
            ;im2 = cordata[*,*,2]
            ;im3 = cordata[*,*,3]
            diff=fltarr(s[1], s[2], s[3])
            diff[*,*,0] = (im0 - im1); - (im2 - im3)
            diff[*,*,1] = (im1 - im0); - (im3 - im2)
            ;diff[*,*,2] = (im2 - im3) - (im0 - im1) ; inverse of diff_a
            ;diff[*,*,3] = (im3 - im2) - (im1 - im0) ; inverse of diff_b
            ; Reference image is diff[*,*,0]
            ; Run image cross-correlation on all difference images with respect to reference
            ; Offset initial values are nodx, nody IN PIXELS
            xoffset = chopx
            yoffset = chopy
            cormerged = abs(diff[*,*,0])
            for i=1, s[3]-1 do begin
                cmat=correl_images(diff[*,*,0], diff[*,*,i], xoff=chopx, yoff=chopy, xshift=30, yshift=30)
                corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=chopx, YOFF_INIT=chopy
                cormerged=cormerged+abs(shift(diff[*,*,i],xopt,yopt))
                ;print,'XOPTYOPT',xopt,yopt
            endfor  
        endif
        if cormerge eq 'COR' then begin
           drip_message,'drip_merge - Using cross-correlation to merge chop/nod frames'
          
           cordata = data[border:s[1]-border-1,border:s[2]-border-1] ; use input data (usually undistorted and stacked)
           ;cordata=data
           ;s = size ( cordata )
           s = size(data)
           cormerged=fltarr(s[1],s[2])
           ; CORREL_OPTIMIZE TEST **********
           ; Run image cross-correlation on all difference images with respect to reference
           ; cross correlate chop with 2x reduction
           xyshift =16
           cmat=correl_images(cordata, -cordata, xoff=chopx, yoff=chopy, xshift=xyshift, yshift=xyshift, $
                              reduction=8)
           corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=chopx, YOFF_INIT=chopy
           xopt2=xopt
           yopt2=yopt
           ; cross correlate chop with 1x reduction over lower distance
           xyshift = 8
           cmat=correl_images(cordata, -cordata, xoff=xopt2, yoff=yopt2, xshift=xyshift, yshift=xyshift)
           corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=xopt2, YOFF_INIT=yopt2
           newchopx=xopt
           newchopy=yopt
           ;print,'chop optimized x/y',xopt,yopt    
           chopx=newchopx
           chopy=newchopy
        endif   
        if cormerge eq 'CENT' then begin
          NPEAKS=2
          findpeaksout=fltarr(2)
          editfile = replicate(0.,s[1],s[2])
          junk = drip_peakfind(data,data,NPEAKS=NPEAKS,STARS=findpeaksout,THRESH=15, TSTEP=.25)
          centerarr = replicate(s[1]/2,2,NPEAKS)                    
          diffarr=findpeaksout-centerarr          
          dist=(diffarr[0,*])^2+(diffarr[1,*])^2
          print, findpeaksout[0,*], findpeaksout[1,*]

          minval=min(dist)
          entry=where(dist eq minval)
          base_coords=findpeaksout[*,entry]
          basepixval=data[base_coords[0],base_coords[1]]
          if (basepixval lt 0) then editfile=-editfile;adjust for  basepixval being -

          for val=0,(NPEAKS-1) do begin
             temp=findpeaksout[*,val]
             pixval=data[temp[0],temp[1]]
             move= base_coords - temp
             if (pixval lt 0) then begin ;check if added img is pos or neg
                editfile= editfile-shift(data, move) ;negitive images
             endif else begin
                editfile= editfile+shift(data, move) ;positive images
             endelse
          endfor
         merged = editfile/NPEAKS

          ;centdata = odata[*,0:254]
          ;centmerged=find_peak_all(odata)/2  ; Divide by 2 to get mean pixel values
          ;cormerge = 'N'  ; DON'T TRY TO USE CENTROID TO MERGE
      endif else begin            
        ; shift and merge
        if (sqrt(chopx^2+chopy^2)) gt 192 then begin ; was resize*128
            merged=data
        endif else merged=(data-shift(data,chopx,chopy))/2  ; mean
      endelse  
        break
    end
    'C2N': ; 2 position chop with nod
    'C2ND': ; 2 position chop with nod and dither
    'MAP': begin ; MAPping Mode
       ;** find chop distances
       ;chopdist=plate_scale*float(drip_getpar(header,'CHPAMP')) ;    7.274 pix/V (palomar)
       chpcoordsys=drip_getpar(header,'CHPCOORD') ; Get chop coord system: 0=SIRF, 1=TARF, 2=ERF
       nodcoordsys=drip_getpar(header,'NODCOORD') ; Get nod coord system: 0=SIRF, 1=TARF, 2=ERF
       sky_angle=float(drip_getpar(header,'SKY_ANGL'))*!pi/180.0
       ;print,drip_getpar(header,'CHPAMP1')
       chopdist=float(drip_getpar(header,'CHPAMP1'))*2; *2 MCCS sends champ1/2, [was /plate_scale]
       chopang=float(drip_getpar(header,'CHPANGLE'))
       ;chopdist=float(chopdist)
       chopang=!pi/180.0*chopang
       chopx=chopdist*sin(chopang)/x_plate_scale
       chopy=chopdist*cos(chopang)/y_plate_scale 

       ;** find nod distances
       ;nodbeam=drip_getpar(header,'NODBEAM')
       nodbeam=drip_getpar(header,'NODBEAMN')
       ;-- with NODDIST and NODANGLE
       noddist=drip_getpar(header,'NODAMP')
       
       nod_angle=(drip_getpar(header,'NODANGLE'))*!pi/180.0
       ;noddist=7.274*drip_getpar(header,'NODRAAS')
       ;nodang=drip_getpar(header,'NODDECAS')
       noddist=float(noddist); /plate_scale
       nodang=nod_angle ;  -sky_angle  ; rotation to SIRF
       nodx=noddist*sin(nodang)/x_plate_scale  
       nody=noddist*cos(nodang)/y_plate_scale
       ;-- with NODRAAS and NODDECAS
       nodraas=float(drip_getpar(header,'NODRAAS'))
       noddecas=float(drip_getpar(header,'NODDECAS'))
          
       
       if (chpcoordsys eq 2) then begin
          erf_chopx = (chopx*cos(sky_angle) + chopy*sin(sky_angle))
          erf_chopy = (chopy*cos(sky_angle) - chopx*sin(sky_angle))
          chopx = erf_chopx
          chopy = erf_chopy
       endif
       
       if (nodcoordsys eq 2) then begin
          erf_nodx = (nodx*cos(sky_angle) + nody*sin(sky_angle))
          erf_nody = (nody*cos(sky_angle) - nodx*sin(sky_angle))
          nodx = erf_nodx
          nody = erf_nody
       endif
       
       ;print,'CHPNOD =',chopx,chopy,nodx,nody
       
       ;sky_angle=269.0*!pi/180.0

       ; rotate field according to sky angle, the angle between NORTH and 
       ; "up" on the detector
       ;sina=sin(sky_angle)
       ;cosa=cos(sky_angle)
       ;drip_message,'cosasina: '+string(cosa)+string(sina)
       ; nodx=nodraas*cosa+noddecas*sina
       ; nody=-nodraas*sina+noddecas*cosa
       ;nodx=0
       ;nody=0
       ; make arcsec to pixel
       ;arcsecppixX=0.415 ; for palomar 2007
       ;arcsecppixY=0.44 ; for palomar 2007
       ;arcsecppixX=plate_scale ; for SOFIA
       ;arcsecppixY=plate_scale ; for SOFIA
       ;nodx=nodx/arcsecppixX
       ;nody=nody/arcsecppixY

       ;** performs shifts and additions
       ; add chop cycle images
       ;chopx=round(chopx)
       ;chopy=round(chopy)
       ;nodx=round(nodx)
       ;nody=round(nody)
       ;drip_message,'chopx='+string(chopx)+' chopy='+string(chopy)
       ;drip_message,'sky_angle='+string(sky_angle)
       ;drip_message,'nodx='+string(nodx)+' nody='+string(nody)
       
       ;** multiply by resize due to supersampling in undistort
       chopx=chopx;*=resize
       chopy=chopy;*=resize
       nodx=nodx;*=resize
       nody=nody;*=resize
       ;print,'chop from FITS header x/y',chopx,chopy
       ;print,'nod from FITS header x/y',nodx,nody

       ;** CORREL_IMAGES **********
       cormerge=drip_getpar(header,'CORMERGE') ; Keyword replace flag for merge method:
                                               ; CORMERGE = 'COR' then use
                                               ; cross-correlation
                                               ; CORMERGE = 'CORFLT' does cross-cor
                                               ; on flatfielded data (skips undistort
                                               ; and stack)
                                               ; CORMERGE = 'CENT' then use centroid
                                               ; CORMERGE = 'N' then use
                                               ; nominal nod and chop positions
                                               
       ; Check for 'Nod-match-chop' mode: chop amplitude = nod amplitude AND
       ; chop angle - nod angle = 180 degrees
       ; 
       ; If 'Nod-match-chop' then bipass the merge algorithm and return 
       ; input data (stacked)
       chopangr=float(drip_getpar(header,'CHPANGLR'))
       nodangr=float(drip_getpar(header,'NODANGLR'))
       if ((round(noddist) eq round(chopdist)) and (abs(nodangr-chopangr) eq 180)) then begin
          cormerge = 'N'
          ; If the nod is smaller than 1/2 the array width (128 pixels), then
          ; assume that the nod is on-chip and subtract nods by shifting (NODAMP)
          if (nodbeam eq 0) then begin
             merged=data/2.0  ; mean 
             ;print, 'on-chip AAAAA'
          endif else begin
             merged=-(data/2.0)  ; mean
             ;print, 'on-chip BBBBB'
          endelse
          ;merged = data/2.0  ; returns mean value of choped images
          break
       endif
                                   
       if cormerge eq 'CORFLT' then begin
           drip_message,'drip_merge - Using cross-correlation on FLAT data to merge chop/nod frames'
           cordata = flatted[*,0:254,*]  ; Use flatfielded data (no undistort, no stack)
           s = size(cordata)
           cormerged=fltarr(s[1],s[2])
           ; CORREL_OPTIMIZE TEST **********
           ; First make difference image of all chop/nod pairs and their
           ; inverses
           im0 = cordata[*,*,0]
           im1 = cordata[*,*,1]
           im2 = cordata[*,*,2]
           im3 = cordata[*,*,3]
           diff=fltarr(s[1], s[2], s[3])
           diff[*,*,0] = (im0 - im1) - (im2 - im3)
           diff[*,*,1] = (im1 - im0) - (im3 - im2)
           diff[*,*,2] = (im2 - im3) - (im0 - im1) ; inverse of diff_a
           diff[*,*,3] = (im3 - im2) - (im1 - im0) ; inverse of diff_b
           ; Reference image is diff[*,*,0]
           ; Run image cross-correlation on all difference images with respect to reference
           chopx/=resize
           chopy/=resize
           nodx/=resize
           nody/=resize
           xyshift = 7
           ;cormerged = abs(diff[*,*,0])
           ;for i=1, s[3]-1 do begin
               cmat=correl_images(diff[*,*,0], diff[*,*,1], xoff=chopx, yoff=chopy, xshift=xyshift, yshift=xyshift)
               corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=chopx, YOFF_INIT=chopy
               ;cmat=correl_images(diff[*,*,0], diff[*,*,1], xoff=xopt, yoff=yopt,mag=2);, xshift=xyshift, yshift=xyshift)
               ;corrmat_analyze, cmat, x, y, XOFF_INIT=xopt, YOFF_INIT=yopt,mag=2            
               chopmerged0=abs(diff[*,*,0])+abs(shift(diff[*,*,1],xopt,yopt))
               newchopx=xopt
               newchopy=yopt
               ; print,'chop1 x/y',xopt,yopt

               cmat=correl_images(diff[*,*,2], diff[*,*,3], xoff=chopx, yoff=chopy, xshift=xyshift, yshift=xyshift)
               corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=chopx, YOFF_INIT=chopy
               ;cmat=correl_images(diff[*,*,2], diff[*,*,3], xoff=xopt, yoff=yopt,mag=2);, xshift=xyshift, yshift=xyshift)
               ;corrmat_analyze, cmat, x, y, XOFF_INIT=xopt, YOFF_INIT=yopt,mag=2
               chopmerged1=abs(diff[*,*,2])+abs(shift(diff[*,*,3],xopt,yopt))
               newchopx=(newchopx+xopt)/2
               newchopy=(newchopy+yopt)/2
               ; print,'chop2 x/y',xopt,yopt

               cmat=correl_images(chopmerged0, chopmerged1, xoff=nodx, yoff=nody, xshift=xyshift, yshift=xyshift)
               corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=nodx, YOFF_INIT=nody
               ;cmat=correl_images(chopmerged0, chopmerged1, xoff=xopt, yoff=yopt, mag=2);, xshift=xyshift, yshift=xyshift)
               ;corrmat_analyze, cmat, x, y, XOFF_INIT=xopt, YOFF_INIT=yopt,mag=2
               cormerged=(chopmerged0+shift(chopmerged1,xopt,yopt))/2   ; mean
               newnodx=xopt
               newnody=yopt
               ;print,'nod x/y',xopt,yopt
               chopx=newchopx*resize
               chopy=newchopy*resize
               nodx=newnodx*resize
               nody=newnody*resize
           ;endfor  
       endif
       
       if (cormerge eq 'COR') then begin
           drip_message,'drip_merge - Using cross-correlation to merge chop/nod frames'
          
           cordata = data[border:s[1]-border-1,border:s[2]-border-1] ; use input data (usually undistorted and stacked)
           ;cordata=data
           ;s = size ( cordata )
           s = size(data)
           cormerged=fltarr(s[1],s[2])
           ; CORREL_OPTIMIZE TEST **********
           ; Run image cross-correlation on all difference images with respect to reference
           ; cross correlate chop with 2x reduction
           xyshift =25
           cmat=correl_images(cordata, -cordata, xoff=chopx, yoff=chopy, xshift=xyshift, yshift=xyshift, $
                              reduction=8)
           corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=chopx, YOFF_INIT=chopy
           xopt2=xopt
           yopt2=yopt
           ; cross correlate chop with 1x reduction over lower distance
           xyshift = 8
           cmat=correl_images(cordata, -cordata, xoff=xopt2, yoff=yopt2, xshift=xyshift, yshift=xyshift)
           corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=xopt2, YOFF_INIT=yopt2
           newchopx=xopt
           newchopy=yopt
           ;print,'chop optimized x/y',xopt,yopt
           newnodx=nodx
           newnody=nody
           if (sqrt(nodx^2+nody^2)) lt 192 then begin  ; was resize*128
               ; cross correlate nod 
               xyshift = 25
               cmat=correl_images(cordata, -cordata, xoff=nodx, yoff=nody, xshift=xyshift, yshift=xyshift, $
                              reduction=8)
               corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=nodx, YOFF_INIT=nody
               xopt2=xopt
               yopt2=yopt
               ; cross correlate nod with 1x reduction and lower distance
               xyshift = 8
               cmat=correl_images(cordata, -cordata, xoff=xopt2, yoff=yopt2, xshift=xyshift, yshift=xyshift)
               corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=xopt2, YOFF_INIT=yopt2
               newnodx=xopt
               newnody=yopt
               ;print,'nod optimized x/y',xopt,yopt
           endif    
           chopx=newchopx
           chopy=newchopy
           nodx=newnodx
           nody=newnody
           ; merged=cormerged
       endif
       if cormerge eq 'CENT' then begin
          
          NPEAKS=4
          findpeaksout=fltarr(2)
          editfile = replicate(0.,s[1],s[2])
          distnod = sqrt(nodx^2+nody^2)
          distchop = sqrt(chopx^2+chopy^2)
          junk = drip_peakfind(data,data,NPEAKS=NPEAKS,STARS=findpeaksout,THRESH=15, TSTEP=.25, CHOPNODDIST=[distchop,distnod])
          NPEAKS = n_elements(findpeaksout[0,*])
          centerarr = replicate(s[1]/2,2,NPEAKS)                    
          diffarr=findpeaksout-centerarr          
          dist=(diffarr[0,*])^2+(diffarr[1,*])^2
          ;print,'findpeaksout', findpeaksout
          ;atv22, data
          ;atvplot, findpeaksout[0,*], findpeaksout[1,*], psym=4
          
          print,'dist',dist
          minval=min(dist)
          entry=where(dist eq minval)
          base_coords=findpeaksout[*,entry]
          basepixval=data[base_coords[0],base_coords[1]]
          print,'basepixval',basepixval
          if (basepixval lt 0) then editfile=-editfile;adjust for  basepixval being -

          for val=0,(NPEAKS-1) do begin
             temp=findpeaksout[*,val]
             pixval=data[temp[0],temp[1]]
             ;print,'pixval',pixval
             move= base_coords - temp            
             if (pixval lt 0) then begin ;check if added img is pos or neg
                editfile= editfile-shift(data, move) ;negitive images
             endif else begin
                editfile= editfile+shift(data, move) ;positive images
             endelse
          endfor 
          merged = editfile/NPEAKS
          
         ;cormerge = 'N'         ; DON'T TRY TO USE CENTROID TO MERGE
           ;centdata = odata[*,0:254]
           ;centmerged=find_peak_all(data)/4 ; Divide by 4 to get mean pixel values
       endif
       if (cormerge eq 'COR') or (cormerge eq 'CORFLT') or (cormerge eq 'N') then begin
          
          ;** merge choped frames
          if (sqrt(chopx^2+chopy^2)) gt 192 then mergechop=data $
          else mergechop=(data-shift(data,chopx,chopy))/2 ; mean
          ;atv22,mergechop

          ;** add nod cycle images
          ; If the nod is larger than 1/2 the array width (128 pixels), then assume
          ; that the nod is off-chip and subtract nods without shifting
          if (sqrt(nodx^2+nody^2)) gt 192 then begin ;was resize*128
             if (nodbeam eq 0) then merged = mergechop $
             else merged = -mergechop
             print, 'off-chip BBBBBBB'
          endif else begin
          ; If the nod is smaller than 1/2 the array width (128 pixels), then
          ; assume that the nod is on-chip and subtract nods by shifting (NODAMP)
          if (nodbeam eq 0) then begin
             merged=(mergechop-shift(mergechop,nodx,nody))/2  ; mean 
             print, 'on-chip AAAAA'
          endif else begin
             merged=-(mergechop-shift(mergechop,nodx,nody))/2  ; mean
             print, 'on-chip BBBBB'
          endelse
       endelse
       endif
       break
   end
   'C3D': begin ; 3 position chop with dither
       ;find chop distances
       ;chopdist=7.274*float(drip_getpar(header,'CHPAMP'))
       chopdist=float(drip_getpar(header,'CHPAMP1'))/plate_scale
       chopang=float(drip_getpar(header,'CHPANGLE'))
       chopdist=float(chopdist)
       chopang=!pi/180*chopang
       chopx=chopdist*sin(chopang)
       chopy=-chopdist*cos(chopang)
       ; multiply by 2 due to supersampling in undistort
       chopx*=resize
       chopy*=resize
       ; shift and coadd
       merged=(data-shift(data,chopx,chopy)-shift(data,-chopx,-chopy))/3  ; mean
       break
   end
   'CM':begin ; multi positon chop
      chopnum=fix(drip_getpar(header,'CHPNPOS'))
      ; get chop positions
      chpang=fltarr(chopnum-1)
      chpamp=fltarr(chopnum-1)
      chopx=fltarr(chopnum-1)
      chopy=fltarr(chopnum-1)
      for i=0,chopnum-2 do begin
          nrstr=string(i+1,format='(I1)')
          chpang[i]=float(drip_getpar(header,'CHPANGLE'+nrstr))
          chpamp[i]=float(drip_getpar(header,'CHPAMP1'+nrstr))
          chopx[i]=chpamp[i]*sin(chpang/180*!pi)/3*4
          chopy[i]=-chpamp[i]*cos(chpang/180*!pi)/3*4
          ;print,'chopx/y=',chopx[i],chopy[i]
          chopx[i]*=resize
          chopy[i]*=resize
      endfor
      ; perform shifts and additions
      merged=data
      for i=0,chopnum-2 do begin
          merged-=shift(data,chopx[i],chopy[i])
      endfor
      merged=merged/(chopnum-2)  ; mean
      break
  end
  'STARE':begin ; STARE
      merged=data
      break
  end
  'TEST':begin ; TEST
      ;xoff=drip_getpar(header,'TESTXOFF')
      ;yoff=drip_getpar(header,'TESTYOFF')
      submode=strtrim(drip_getpar(header,'TESTMRGE'),2)
      switch submode of
          'MED':
          'ADD':
          'SUB': begin
              merged=data
              break
          end
          'CHOP':
          'CHOP-' : begin
              ; get chop distances
              chopdist=float(drip_getpar(header,'CHPAMP1'))
              chopang=float(drip_getpar(header,'CHPANGLE'))
              chopdist=float(chopdist)
              chopang=!pi/180*chopang
              chopx=chopdist*sin(chopang)
              chopy=-chopdist*cos(chopang)
              ; multiply by 2 due to supersampling in undistort
              chopx*=resize
              chopy*=resize
              ; shift and merge
              merged=data-shift(data,chopx,chopy)
              break
          end
          else: if (size(data))[0] eq 3 then $
            merged=median(data,dimension=3) $
            else merged=data
      endswitch
      break
  end
  else:begin
      drip_message, 'drip_merge - invalid instrument mode - returning images'
      merged=data
  endelse
endswitch


return, merged

;if (cormerge eq 'COR') then begin
;    ;atv22,cormerged
;    return, merged 
;    ;return, cormerged
;endif 

;if (cormerge eq 'CENT') then begin
;    return, centmerged
;endif else begin
;    return, merged
;endelse

end
