import numpy
import time
import numpy.random
import scipy
import scipy.special
import Gnuplot
import pyfits
import matplotlib.cm as cm
import matplotlib.mlab as mlab
import matplotlib.pyplot as pyplot

class Grism( object ):
    def __init__(self, name, sigma, delta, n, l_start, l_stop):
        self.name = name
        self.sigma = sigma
        self.delta = delta
        self.n = n
        self.l_start = l_start
        self.l_stop = l_stop

    def calc_beta(self, wl, m):
        beta = numpy.degrees(numpy.arcsin( m*wl/self.sigma - self.n*numpy.sin(numpy.radians(self.delta)))) + self.delta
        return beta

def draw_airy(X, Y, x_c, y_c, wl):
    # l = lambda (in cm)
    pixel_size = 50e-4 # length of side of pixel (in cm)
    l = wl/pixel_size
    f_length = 15.494/pixel_size # focal length (in pixels)
    d = 2.54/pixel_size # Beam diameter (in pixels)
    r = [((X-x_c)**2+(Y-y_c)**2)**(0.5)] # radius from optical axis (in pixels)
    bm = scipy.where(r[0] < 15)
    x_airy = 3.1415926*(numpy.array(r))/((l*(f_length/d))) # 
    image = numpy.zeros([len(X), len(X[0])])
    for pixel in zip(*bm):
        image[pixel[0]][pixel[1]] = (2*scipy.special.jv(1, x_airy[0][pixel[0]][pixel[1]])/x_airy[0][pixel[0]][pixel[1]])**2.0
    return image

class Slit( object ):
    def __init__(self, length, width, PSF_FWHM):
        self.FWHM = PSF_FWHM
        self.length = length
        self.width = width
        if (length > width):
            self.orientation = 1   # Cross-Dispersed
            self.length_mult = 3
            self.width_mult = 3
        else:
            self.orientation = 0   # Single-order
            self.length_mult = 3
            self.width_mult = 3
        self.object_location = -1.0

    def point_source(self, position):
        self.object_location = position     # position along slit 0= top, 1 = bottom

    def slit_image(self, y_strength):
        wl = 8e-4
        x = numpy.arange(0, self.length*self.length_mult+1, 1.0)
        y = numpy.arange(0, self.width*self.width_mult+1, 1.0)
        X, Y = numpy.meshgrid(x, y)
        #ptsource = mlab.bivariate_normal(X, Y, self.FWHM, self.FWHM, len(x)/2.0+(self.object_location-0.5)*self.length, len(y)/2.0)
        ptsource = draw_airy(X, Y, len(x)/2.0+(self.object_location-0.5)*self.length, len(y)/2.0, wl)

        sky = numpy.zeros([len(y), len(x)])
        for i in numpy.arange(len(x)/2.0-self.length/2.0, len(x)/2.0+self.length/2.0, 1.0):
            for j in numpy.arange(len(y)/2.0-self.width/2.0, len(y)/2.0+self.width/2.0, 1.0):
                sky += ((numpy.random.randn(1))**2.0)*draw_airy(X, Y, i, j, wl)
                #sky += ((numpy.random.randn(1))**2.0)*mlab.bivariate_normal(X, Y, self.FWHM, self.FWHM, i, j)

        #ptsource = mlab.bivariate_normal
        composite = numpy.round(sky) + numpy.round(ptsource*500.0*y_strength)
        return composite


plt = Gnuplot.Gnuplot()

#a = Gnuplot.Data(x, Z[150], with_='lines')
#b = Gnuplot.Data(y, zip(*Z)[100], with_='lines')
#plt('set logscale y')
#plt('set yrange [1: 2000.0]')
#plt('set xrange [0:255]')
#plt.plot(a, b)
#im = pyplot.imshow(Z, cmap=cm.gray,origin='lower', extent=[0,256,0,256])
#pyplot.show()

wl = numpy.linspace(5, 9, 101)

G1 = Grism('G1', 25.0, 6.16, 3.43, 4.9, 7.8)
G2 = Grism('G2', 87.0, 32.6, 3.43, 4.9, 7.8)
xdisp_beta = G1.calc_beta(wl, 1.0)
beta_m14 = G2.calc_beta(wl, 14.0)
beta_m15 = G2.calc_beta(wl, 15.0)
beta_m16 = G2.calc_beta(wl, 16.0)
beta_m17 = G2.calc_beta(wl, 17.0)
beta_m18 = G2.calc_beta(wl, 18.0)
beta_m19 = G2.calc_beta(wl, 19.0)
beta_m20 = G2.calc_beta(wl, 20.0)
beta_m21 = G2.calc_beta(wl, 21.0)
beta_m22 = G2.calc_beta(wl, 22.0)
beta_m23 = G2.calc_beta(wl, 23.0)

focal_length = 1.5748e5 #microns
xpos = numpy.tan(numpy.radians(xdisp_beta))*focal_length/50.0
ypos_m14 = numpy.tan(numpy.radians(beta_m14))*focal_length/50.0
ypos_m15 = numpy.tan(numpy.radians(beta_m15))*focal_length/50.0
ypos_m16 = numpy.tan(numpy.radians(beta_m16))*focal_length/50.0
ypos_m17 = numpy.tan(numpy.radians(beta_m17))*focal_length/50.0
ypos_m18 = numpy.tan(numpy.radians(beta_m18))*focal_length/50.0
ypos_m19 = numpy.tan(numpy.radians(beta_m19))*focal_length/50.0
ypos_m20 = numpy.tan(numpy.radians(beta_m20))*focal_length/50.0
ypos_m21 = numpy.tan(numpy.radians(beta_m21))*focal_length/50.0
ypos_m22 = numpy.tan(numpy.radians(beta_m22))*focal_length/50.0
ypos_m23 = numpy.tan(numpy.radians(beta_m23))*focal_length/50.0

m14 = Gnuplot.Data(xpos, ypos_m14, with_='lines')
m15 = Gnuplot.Data(xpos, ypos_m15, with_='lines')
m16 = Gnuplot.Data(xpos, ypos_m16, with_='lines')
m17 = Gnuplot.Data(xpos, ypos_m17, with_='lines')
m18 = Gnuplot.Data(xpos, ypos_m18, with_='lines')
m19 = Gnuplot.Data(xpos, ypos_m19, with_='lines')
m20 = Gnuplot.Data(xpos, ypos_m20, with_='lines')
m21 = Gnuplot.Data(xpos, ypos_m21, with_='lines')
m22 = Gnuplot.Data(xpos, ypos_m22, with_='lines')
m23 = Gnuplot.Data(xpos, ypos_m23, with_='lines')

#plt('set xrange [-128:128]')
#plt('set yrange [-128:128]')
plt('set xlabel "Cross-Dispersion"')
plt('set ylabel "Dispersion"')
plt.plot(m14, m15, m16, m17, m18, m19, m20, m21, m22, m23)
print asdf
