;******************************************************************************
;     Input Variables
;******************************************************************************
pro drip_xplot_mode::setinitialdata

;widget ids
self.xzoomplot_base=self.xplot->getdata(/xzoomplot_base)
self.pixmap_wid = self.xplot->getdata(/pixmap_wid)
self.plotwin_wid= self.xplot->getdata(/plotwin_wid)
self.plotwin=self.xplot->getdata(/pltwin)
self.mw=self.xplot->getdata(/mw)

;data
self.allwave=self.xplot->getdata(/allwave)
self.allpixel=self.xplot->getdata(/allpixel)
self.allflux=self.xplot->getdata(/allflux)
self.oplotn=self.xplot->getdata(/oplotn)

;properties
self.plotsize=self.xplot->getdata(/plotsize)

end

;******************************************************************************
;     INIT
;******************************************************************************
function drip_xplot_mode::INIT,xplot

;data
self.allwave=ptrarr(100,/allocate_heap)
self.allpixel=ptrarr(100,/allocate_heap)
self.allflux=ptrarr(100,/allocate_heap)

;object
self.xplot=xplot

return,1
end



;******************************************************************************
;     DRIP_XPLOT_MODE__DEFINE
;******************************************************************************

pro drip_xplot_mode__define

struct={drip_xplot_mode,$
        $;widget ids
        xzoomplot_base:0l,$     ;xzoomplot base widget id
        mw:obj_new(),$                 ;message window widget id
        plotwin:0,$             ;id for draw widget
        plotwin_wid:0l,$        ;id for plot window
        pixmap_wid:0l,$         ;id for pixmap
        $;data pointers
        allwave:ptrarr(100),$   ;all the wave values
        allpixel:ptrarr(100),$  ;all the pixel values
        allflux:ptrarr(100),$   ;all the flux values
        oplotn:0.,$             ;number of plots
        $;properties
        eventxy:[0.,0.],$       ;event xy
        xy:[0.,0.],$            ;converted xy
        plotsize:[0.,0.],$      ;plotsize x and y
        $;object
        xplot:obj_new()$       ;xplot display object
        }

end
