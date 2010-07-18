; NAME:
;     DRIP_MENU - Version 1.7.0
;
; PURPOSE:
;     Menu item manager for the GUI
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     Manager Objects: Sends them the reset command if the interface
;                      is reset
;     CW_DRIP_MW: Used to send messages to the user
;     DRIP_PIPEMAN: MENU checks if there is unsaved data upon exit
;     DRIP_DATAMAN: Is used to store FITS data
;
; PROCEDURE:
;     MENU handles general GUI functions like EXIT, RESET and opening
;     normal (non-forcast) FITS files.
;
; RESTRICTIONS:
;     None
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, 2002
;     Modified:   Alfred Lee, Cornell University, January 2003
;                 Decided to give this version a number
;     Modified:   Alfred Lee, CU, January 30, 2003
;                 Added functionality to various routines.  Esp. NEW
;     Modified:   Alfred Lee, CU March 9, 2003
;                 Added AUTO_OPEN routine to handle filelist additions from the
;                 AUTO object.  Also adjusted AUTO and RUN to handle calls from
;                 the AUTO object.
;     Modified:   Marc Berthoud, CU, July 18. 2003
;                 in menu::run: added condition for hourglass
;     Modified:   Marc Berthoud, CU, July 23. 2003
;                 added fileinfo widget id, menu::start and its use in
;                 menu::new and menu::run
;     Modified:   Marc Berthoud, CU, May 2004
;                 added menu->file->set logfile
;     Modified:   Marc Berthoud, CU, July 2004
;                 adapted for new drip pipes
;     Modified:   Marc Berthoud, CU, July 2006
;                 - adapted for use of DAta Products (DAPs)
;                 - Added multiple fits loading
;                 - Moved all pipe interaction to pipeman
;     Modified:   Marc Berthoud, CU, September 2007
;                 - Added responsibility for own widgets
;                 - Added selection of displays for opening fits
;     Modified:   Nirbhik Chitrakar, CU, August 2008
;                 - Added pipeman element in the struct
;                 - modified exit proc to warn user about unsaved data

;******************************************************************************
;     OPEN_FITS - Open FITS file
;******************************************************************************
pro drip_menu::open_fits, event
;let user choose file
files=dialog_pickfile(filter=*self.loadfilter, $
      /fix_filter, /must_exist, /read, get_path=path, $
      path=self.loadfitspath, dialog_parent=event.top, /multiple_files )
if files[0] ne '' then begin
    ; determine common filename length -> clen
    n=(size(files))[1]
    names=files
    for i=0,n-1 do begin
        filename=strmid(files[i],strlen(path))
        names[i]=strmid(filename,0,strpos(filename,'.',/reverse_search))
    endfor
    if n gt 1 then begin
        clen=strlen(names[0])
        i=1
        repeat begin
            if strcmp(names[0],names[i],clen) then i=i+1 else clen=clen-1
        endrep until (i eq n-1) or (clen eq 0)
        print,'clen=',clen
        print,names
    endif else clen=0
    ; in names replace chars like . / - ? with '_' (else create_struct fails)
    for i=0,n-1 do begin
        s=names[i] ; this has 2 be done b/c strput,names[i] fails
        for j=0,strlen(s)-1 do begin
            if stregex(strmid(s,j),'[0-9A-Za-z]') ne 0 then $
              strput,s,'_',j
        endfor
        names[i]=s
    endfor
    ; read first file -> make structure header
    data=readfits(files[0],header)
    filename=strmid(files[0],strlen(path))
    dataproduct={name:names[0], n:n, file0:filename, path:path, $
                 header0:header}
    ; make data names
    dnames='dat'+strmid(names,clen)
    dataproduct=create_struct(dataproduct,dnames[0],data)
    ; add other files to structure
    for i=1,n-1 do begin
        data=readfits(files[i])
        dataproduct=create_struct(dataproduct,dnames[i],data)
    endfor
    ; send to dataman, print message
    self.dataman->setdap,names[0], dataproduct
    self.mw->print, 'loading file ' + filename + ' in data product ' + names[0]
    ; identify display, send new dap
    index=where(*self.fitsmenuids eq event.id)
    if size(index,/dimensions) gt 0 then begin
        (*self.disp_sels)[index[0]]->newdap, dapnew=names[0]
    endif
    ; channelcall
    self.dataman->channelcall
    ; store path and loadfilter
    self.loadfitspath=path
    if strmid(filename,strlen(filename)-5) eq '.fits' then $
      *self.loadfilter=['*.fits','*.fit','*.fts']
    if strmid(filename,strlen(filename)-4) eq '.fit' then $
      *self.loadfilter=['*.fit','*.fits','*.fts']
    if strmid(filename,strlen(filename)-4) eq '.fts' then $
      *self.loadfilter=['*.fts','*.fits','*.fit']
endif
end

;******************************************************************************
;     LOGFILE - choose log file
;******************************************************************************

pro drip_menu::logfile, event
; get filename
common gui_config_info, guiconf
logfname=getpar(guiconf,'LOGFILE')
if (size(logfname))[1] ne 7 then logfname=''
logfname=dialog_pickfile(file=logfname)
setpar,guiconf,'LOGFILE',logfname
end

;******************************************************************************
;     RESET - Reset gui.
;******************************************************************************
pro drip_menu::reset, event
; reset objects
for i=0,self.manobjlistn-1 do self.manobjlists[i]->reset
self.dataman->reset
; message
self.mw->print, "GUI reset"
end

;******************************************************************************
;     EXIT - end session
;******************************************************************************

pro drip_menu::exit, event

; querry user for unsaved reduced files
saveflag=self.pipeman->getdata(/saveflag)
skipexit=0 ; flag to set if exit is not requested
if not(saveflag) then begin
   reply=dialog_message('Reduced Data is not saved. Do wish to save it?',$
                        /question, /cancel, /center, dialog_parent=event.top)
   case reply of
      'Yes': self.pipeman->save
        ;if cancel then dont exit
      'Cancel':skipexit=1
      'No':
   endcase
endif else begin
   reply=dialog_message('Are you sure you want to exit?',$
                        /question, /center, dialog_parent=event.top)
   if (reply eq 'No') then skipexit=1
endelse

; exit program is requested
if not(skipexit) then begin
    ; querry configuration name if necessary
    common gui_config_info, guiconf
    conffilename=guiconf[0]
    if strlen(conffilename) eq 0 then begin
       conffilename=dialog_pickfile(/write, title='Save GUI Conf File:',$
                                    file='guiconf.txt')
    endif
    guiconf[0]=conffilename
    ; destroy top widget
    widget_control, event.top, /destroy
endif
end

;******************************************************************************
;     START - Makes widgets
;******************************************************************************

pro drip_menu::start, mbar, disp_sels=disp_sels

;** make all menu options
file_menu=widget_button(mbar, value='File', /menu)
; menu options: Reset
clear=widget_button(file_menu, value='Reset', event_pro='drip_eventhand', $
      uvalue={object:self, method:'reset'})
; make fits open menu (one for every display)
if keyword_set(disp_sels) then begin
    ; make parent menu
    openfits=widget_button(file_menu, value='Open FITS...', /separator, /menu )
    ; get # of displays
    *self.disp_sels=disp_sels
    dispn=size(disp_sels,/n_elements)
    ; loop through displays
    for dispi=0,dispn-1 do begin
        ; get display id
        disp=disp_sels[dispi]->getdata(/disp)
        dispid=string(byte(disp->getdata(/disp_id)))
        ; make sub menu
        menuid=widget_button(openfits,value='Open in Display '+dispid, $
          event_pro='drip_eventhand', uvalue={object:self, method:'open_fits'})
        if dispi eq 0 then *self.fitsmenuids=[menuid] $
          else *self.fitsmenuids=[*self.fitsmenuids,menuid]
    endfor
endif else begin
    ; no dips anal select objects provided -> just have generic Open FITS
    openfits=widget_button(file_menu, value='Open FITS...', /separator, $
      event_pro='drip_eventhand', uvalue={object:self, method:'open_fits'})
    *self.fitsmenuids=[0]
endelse
; menu options: Set Logfile, Quit
logfile=widget_button(file_menu, value='Set Logfile...', $
      event_pro='drip_eventhand', uvalue={object:self, method:'logfile'} )
exit=widget_button(file_menu, value='Quit', event_pro='drip_eventhand', $
      uvalue={object:self, method:'exit'}, /separator)
end

;******************************************************************************
;     CLEANUP - Save settings, free pointer heap variables
;******************************************************************************

pro drip_menu::cleanup
; Save Paths
common gui_config_info, guiconf
setpar,guiconf,'loadfitspath',self.loadfitspath
; free pointers
ptr_free, self.loadfilter
ptr_free, self.disp_sels
ptr_free, self.fitsmenuids
end

;******************************************************************************
;     INIT - Initialize structure
;******************************************************************************

function drip_menu::init, dataman, pipeman, mw, manobjlist
; set standart variables
self.dataman=dataman
self.pipeman=pipeman
self.mw=mw
self.manobjlistn=n_elements(manobjlist)
self.manobjlists=manobjlist
self.disp_sels=ptr_new(/allocate_heap)
self.fitsmenuids=ptr_new(/allocate_heap)
; how to load fits files
self.loadfilter=ptr_new(/allocate_heap)
*self.loadfilter=['*.fits','*.fit','*.fts']
; get loadfitspath (check if entry is valid and path exits)
common gui_config_info, guiconf
loadfitspath=getpar(guiconf,'loadfitspath')
if (size(loadfitspath))[1] ne 7 then self.loadfitspath='.' else begin
    if file_test(loadfitspath) gt 0 then $
      self.loadfitspath=loadfitspath else self.loadfitspath='.'
endelse
return, 1
end

;******************************************************************************
;     DRIP_MENU__DEFINE
;******************************************************************************

pro drip_menu__define
struct={drip_menu, $
        loadfitspath:'', $    ; loading directory for fits images
        loadfilter:ptr_new(),$; filters for loading fits images
        dataman:obj_new(), $  ; data manager
        pipeman:obj_new(),$   ; pipe manager
        manobjlistn:0, $      ; number of manager objects
        manobjlists:objarr(20),$ ; array for manager objects
        disp_sels:ptr_new(),$ ; array of display anal select objects
        fitsmenuids:ptr_new(),$ ; widget id of open fits sub-menus
                                ; is [0] if no disp_sels are available
        mw:obj_new() }        ; message window object
end
