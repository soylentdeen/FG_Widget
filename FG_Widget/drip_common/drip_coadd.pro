; NAME:
;     DRIP_COADD - Version .7.0
;
; PURPOSE:
;     Coadd new sequence to existing data
;
; CALLING SEQUENCE:
;     COADDED=DRIP_COADD(NEWDATA, COADDED, HEADER, BASEHEAD, /FIRST)
;
; INPUTS:
;     NEWDATA - The new reduced image
;     COADDED - Coadded previous images
;     HEADER - The fits header of the new input data file
;     BASEHEAD - The fits header of the first data file
;     /FIRST - Flag for first coadding
;
; OUTPUTS:
;     COADDED - New Coadded Image
;
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS:
;     None.
;
; PROCEDURE:
;     Sum new data over old data
;
; MODIFICATION HISTORY:
;   Written by:   Marc Berthoud, CU, July 2004
;   Modified:     Marc Berthoud, CU, November 2004
;                 Added TPCD and C3PD, changed case to switch
;   Modified:     Marc Berthoud, CU, March 2005
;                 Added TEST mode
;                 Renamed all modes
;   Modified:     Marc Berthoud, Palomar, September 2007
;                 Added use of RA and DEC for noding and dithering
;   Modified:     Luke Keller, Ithaca College June 2010
;                 Added option to coadd using cross correlation of frames

;******************************************************************************
;     DRIP_COADD - Merges data frames
;******************************************************************************

function drip_coadd, newdata, coadded, header, basehead, first=first, n=n

; error check
s=size(newdata)
if s[0] ne 2 then begin
    drip_message, 'drip_coadd - invalid new data array - aborting',/fatal
    return, newdata
endif
cs=size(coadded)
if cs[0] ne 2 then begin
    drip_message, 'drip_coadd - invalid or no previous coadded array - using blank image'
    coadded=newdata
    coadded[*,*]=0.0
endif
hs=size(header)
if (hs[0] ne 1) or (hs[2] ne 7) then drip_message, $
  'drip_coadd - invalid header'
hs=size(basehead)
if (hs[0] ne 1) or (hs[2] ne 7) then drip_message, $
  'drip_coadd - invalid base header'
; initialize variables
newcoadded=fltarr(s[1],s[2])
mode=drip_getpar(header,'INSTMODE')
mode=strtrim(mode,2)
; run appropriate method
switch mode of
    'C2': ; 2 position chop
    'C2N':begin ; 2 position chop with nod
        if keyword_set(first) then newcoadded=newdata $
        else begin
        cormerge=drip_getpar(header,'CORMERGE') ; Keyword replace flag for merge method:
                                               ; CORMERGE = 'Y' then use
                                               ; cross-correlation
                                               ; CORMERGE = 'N' then use
                                               ; nominal nod and chop positions
        ; Use cross correlation to align images                                      
        if (cormerge eq 'COR' OR cormerge eq 'CENT') then begin 
           drip_message,'drip_coadd - Using cross-correlation to coadd frames'
           cmat=correl_images(coadded, newdata, xoff=0, yoff=0, xshift=20, yshift=20)
           corrmat_analyze, cmat, xopt, yopt, XOFF_INIT=0, YOFF_INIT=0           
           newcoadded=coadded+shift(newdata,xopt,yopt)
        ;endif
        ;if cormerge eq 'CENT' then begin ; Use centroids to align images
        ;   ;centdata = odata[*,0:254]
        ;   origin=find_peak_all(odata)
        ;   cormerged=origin
        ;   newcoadded=coadded+
        endif else newcoadded=coadded+newdata
        endelse
        break
    end
    'C2ND': ; C2N with Dither
    'C3D':begin ; 3 position chop with Dither
        ;** shift image from RA, DEC
        ; get original and new ra/dec (ra in hours, dec in degs)
        ;   convert all to degrees
        basera=15.0*float(drip_getpar(basehead,'TELRA'))
        basedec=float(drip_getpar(basehead,'TELDEC'))
        newra=15.0*float(drip_getpar(header,'TELRA'))
        newdec=float(drip_getpar(header,'TELDEC'))
        avgdec=(basedec+newdec)/2.0
        ; make correction for nodding
        if mode eq 'C2ND' then begin
            nodbeam=strtrim(drip_getpar(header,'NODBEAM'),2)
            if nodbeam eq 'B' then begin
                newra=newra-float(drip_getpar(header,'NODRAAS'))/3600.0/ $
                  cos(!pi/180.0*avgdec)
                newdec=newdec-float(drip_getpar(header,'NODDECAS'))/3600.0
            endif
        endif
        raoff=(newra-basera)*cos(!pi/180.0*avgdec)
        decoff=newdec-basedec
        ; convert to seconds then pixels (remember 2x subsampled to match coadd frame format)
        ;arcsecppix=0.43 ; palomar 2007
        arcsecpix=0.75 ; assume telescope is SOFIA
        telescope=drip_getpar(header,'TELESCOP') ; to determine plate scale
        if telescope eq 'PIXELS' then arcsecpix=1.0
        
        raoff=2.0*3600.0*raoff/arcsecppix
        decoff=2.0*3600.0*decoff/arcsecppix
        ; shift image (raoff left, decoff up)    
        
        ;print,'raoff=',raoff,' decoff=',decoff
        ;newshift=shift(newdata,-raoff,decoff)
        
        ;** shift image from DITHERX and DITHERY (remember 2x subsampled to match coadd frame format)
        ditherx=2*(drip_getpar(header,'DITHER_X'))
        dithery=2*(drip_getpar(header,'DITHER_Y'))
        print,'ditherx=',ditherx,' dithery=',dithery
        newshift=shift(newdata,-ditherx,-dithery)
        ;
        
        ; add image to last coadded images
        if keyword_set(first) then newcoadded=newshift $
          else newcoadded=coadded+newshift
        break
    end
    'CM':begin ; multi position chop
        if keyword_set(first) then newcoadded=newdata $
          else newcoadded=coadded+newdata
        break
    end
    'MAP':begin ; MAPping mode
        ;** new map: set size of final map and make map
        nx=fix(drip_getpar(header,'MAPNXPOS'))
        ny=fix(drip_getpar(header,'MAPNYPOS'))
        posx=fix(drip_getpar(header,'MAPPOSX'))-1
        posy=fix(drip_getpar(header,'MAPPOSY'))-1
        intx=fix(drip_getpar(header,'MAPINTX'))
        inty=fix(drip_getpar(header,'MAPINTY'))
        sizex=256+(nx-1)*intx
        sizey=256+(ny-1)*inty
        print,sizex,sizey
        if keyword_set(first) then newcoadded=fltarr(sizex,sizey) $
          else newcoadded=coadded
        newx=posx*intx
        newy=posy*inty
        newcoadded[newx:newx+255,newy:newy+255]=newdata
        break
    end
    'STARE':begin ; STARE
        if keyword_set(first) then newcoadded=newdata $
          else newcoadded=newdata+coadded
        break
    end
    'TEST':begin ; TEST
        submode=drip_getpar(header,'TESTCADD')
        switch submode of
            ; add frames
            'ADD': begin
                if keyword_set(first) then newcoadded=newdata $
                  else newcoadded=newdata+coadded
                break
            end
            ; subtract each other frame
            'SUB': begin
                if keyword_set(first) then newcoadded=newdata $
                  else newcoadded=newdata-coadded
                break
            end
            ; add A's subtract B's
            'ABBA': begin ; use n, add A, subtract B
                if keyword_set(first) then newcoadded=newdata $
                  else if (n+1) mod 4 lt 2 then newcoadded=coadded+newdata $
                    else newcoadded=coadded-newdata
                break
            end
            ; keep all frames (3D image) use first as background
            'LIST_BACKSUB': begin
                if keyword_set(first) then newcoadded=newdata $
                  else begin
                    newsub=newdata-coadded[*,*,0]
                    newcoadded=[[[coadded]],[[newsub]]]
                endelse
                break
            end
            ; full nodding
            'NOD': begin ; use n, chop according to ABBA
                ; get nod distances
                noddist=float(drip_getpar(header,'NODDIST'))
                nodang=float(drip_getpar(header,'NODANGLE'))
                noddist=float(noddist)
                nodang=!pi/180*nodang
                nodx=noddist*sin(nodang)
                nody=-noddist*cos(nodang)
                ; shift and coadd
                if keyword_set(first) then begin
                    newcoadded=newdata-shift(newdata,nodx,nody)
                endif else begin
                    if (n+1) mod 4 lt 2 then begin
                        newcoadded=newdata-shift(newdata,nodx,nody)+coadded
                    endif else begin
                        newcoadded=shift(newdata,nodx,nody)-newdata+coadded
                    endelse
                endelse
                break
            end
            else: if keyword_set(first) then newcoadded=newdata $
              else newcoadded=newdata-coadded
        endswitch
        break
    end
    else:begin
        drip_message, ['drip_coadd - invalid instrument mode', $
                       '  ignoring new data']
        newcoadded=coadded
    endelse
endswitch

return, newcoadded

end
