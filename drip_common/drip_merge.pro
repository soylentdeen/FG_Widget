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

;******************************************************************************
;     DRIP_MERGE - Merges object images
;******************************************************************************

function drip_merge, data, header

; error check
s=size(data)
if s[0] ne 2 then begin
    drip_message, 'drip_merge - Must provide valid new data array',/fatal
    return, data
endif
hs=size(header)
if (hs[0] ne 1) or (hs[2] ne 7) then drip_message, $
  'drip_merge - invalid header'
;**** merge
; initialize variables
s=size(data)
merged=fltarr(s[1],s[2])
mode=drip_getpar(header,'INSTMODE')
mode=strtrim(mode,2)
; run appropriate method
switch mode of
    'C2': begin ; 2 position chop
        ; get chop distances
        chopdist=7.274*float(drip_getpar(header,'CHPAMP'))
        chopang=float(drip_getpar(header,'CHPANGLE'))
        chopdist=float(chopdist)
        chopang=!pi/180*chopang
        chopx=chopdist*sin(chopang)
        chopy=-chopdist*cos(chopang)
        ; multiply by 2 due to supersampling in undistort
        chopx*=2.0
        chopy*=2.0
        ; shift and merge
        merged=data-shift(data,chopx,chopy)
        break
    end
    'C2N': ; 2 position chop with nod
    'C2ND': ; 2 position chop with nod and dither
    'MAP': begin ; MAPping Mode
       ;** find chop distances
       chopdist=7.274*float(drip_getpar(header,'CHPAMP')) ; 7.274 pix/volt
       chopang=float(drip_getpar(header,'CHPANGLE'))
       chopdist=float(chopdist)
       chopang=!pi/180*chopang
       chopx=chopdist*sin(chopang)
       chopy=-chopdist*cos(chopang)
       print,'chopx=',chopx,' chopy=',chopy
       ;** find nod distances
       nodbeam=drip_getpar(header,'NODBEAM')
       ;-- with NODDIST and NODANGLE
       ;noddist=drip_getpar(header,'NODDIST')
       ;nodang=drip_getpar(header,'NODANGLE')
       ;noddist=7.274*drip_getpar(header,'NODRAAS')
       ;nodang=drip_getpar(header,'NODDECAS')
       ;noddist=float(noddist) ; took out *4/3
       ;nodang=!pi/180*nodang
       ;nodx=noddist*sin(nodang)
       ;nody=-noddist*cos(nodang)
       ;-- with NODRAAS and NODDECAS
       nodraas=float(drip_getpar(header,'NODRAAS'))
       noddecas=float(drip_getpar(header,'NODDECAS'))
       sky_angle=float(drip_getpar(header,'SKY_ANGL'))*!pi/180.0
       ; turn according to sky angle
       sina=sin(sky_angle)
       cosa=cos(sky_angle)
       nodx=nodraas*cosa+noddecas*sina
       nody=-nodraas*sina+noddecas*cosa
       ; make arcsec to pixel
       arcsecppixX=0.415
       arcsecppixY=0.44
       nodx=nodx/arcsecppixX
       nody=nody/arcsecppixY
       ; multiply by 2 due to supersampling in undistort
       chopx*=2.0
       chopy*=2.0
       nodx*=2.0
       nody*=2.0
       print,'nodx=',nodx,' nody=',nody
       ;** performs shifts and additions
       ; add chop cycle images
       mergechop=data-shift(data,chopx,chopy)
       ; add nod cycle images
       print,nodbeam
       if nodbeam eq 'A' then $
         merged=mergechop-shift(mergechop,-nodx,-nody) else $
         merged=shift(mergechop,-nodx,-nody)-mergechop
       break
   end
   'C3D': begin ; 3 position chop with dither
       ;find chop distances
       chopdist=7.274*float(drip_getpar(header,'CHPAMP'))
       chopang=float(drip_getpar(header,'CHPANGLE'))
       chopdist=float(chopdist)
       chopang=!pi/180*chopang
       chopx=chopdist*sin(chopang)
       chopy=-chopdist*cos(chopang)
       ; multiply by 2 due to supersampling in undistort
       chopx*=2.0
       chopy*=2.0
       ; shift and coadd
       merged=data-shift(data,chopx,chopy)-shift(data,-chopx,-chopy)
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
          chpang[i]=float(drip_getpar(header,'CHPANG'+nrstr))
          chpamp[i]=float(drip_getpar(header,'CHPAMP'+nrstr))
          chopx[i]=chpamp[i]*sin(chpang/180*!pi)/3*4
          chopy[i]=-chpamp[i]*cos(chpang/180*!pi)/3*4
          ;print,'chopx/y=',chopx[i],chopy[i]
          chopx[i]*=2.0
          chopy[i]*=2.0
      endfor
      ; perform shifts and additions
      merged=data
      for i=0,chopnum-2 do begin
          merged-=shift(data,chopx[i],chopy[i])
      endfor
      break
  end
  'STARE':begin ; STARE
      merged=data ; -dark
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
              chopdist=float(drip_getpar(header,'CHPAMP'))
              chopang=float(drip_getpar(header,'CHPANGLE'))
              chopdist=float(chopdist)
              chopang=!pi/180*chopang
              chopx=chopdist*sin(chopang)
              chopy=-chopdist*cos(chopang)
              ; multiply by 2 due to supersampling in undistort
              chopx*=2.0
              chopy*=2.0
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

end
