import numpy
import numpy.random
import scipy
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


class Slit( object ):
    def __init__(self, length, width, PSF_FWHM):
        self.FWHM = PSF_FWHM
        self.length = length
        self.width = width
        if (length > width):
            self.orientation = 1   # Cross-Dispersed
            self.length_mult = 3.0
            self.width_mult = 5.0
        else:
            self.orientation = 0   # Single-order
            self.length_mult = 5.0
            self.width_mult = 3.0
        self.object = -1.0

    def point_source(self, position):
        self.object_location = position     # position along slit 0= top, 1 = bottom

    def slit_image(self, y_strength):
        x = numpy.arange(0, self.length*self.length_mult+1, 1.0)
        y = numpy.arange(0, self.width*self.width_mult+1, 1.0)
        X, Y = numpy.meshgrid(x, y)
        ptsource = mlab.bivariate_normal(X, Y, self.FWHM, self.FWHM, len(x)/2.0+(self.object_location-0.5)*self.length, len(y)/2.0)

        sky = numpy.zeros([len(y), len(x)])
        for i in numpy.arange(len(x)/2.0-self.length/2.0, len(x)/2.0+self.length/2.0, 0.1):
            for j in numpy.arange(len(y)/2.0-self.width/2.0, len(y)/2.0+self.width/2.0, 0.1):
                sky += ((numpy.random.randn(1))**2.0)*mlab.bivariate_normal(X, Y, self.FWHM, self.FWHM, i, j)

        #ptsource = mlab.bivariate_normal
        composite = numpy.round(sky) + numpy.round(ptsource*500.0*y_strength)
        return composite


n_frames = 2

delta = 1.0

x = numpy.arange(0, 256, delta)
y = numpy.arange(0, 256, delta)
X, Y = numpy.meshgrid(x, y)

full_image = []

for i in numpy.arange(n_frames):
    Z = numpy.zeros([len(y), len(x)])
    background = numpy.random.poisson(lam=50, size = [len(y), len(x)])
    Z += background
    
    full_image.append(Z)

full_image = numpy.array(full_image)

hdu = pyfits.PrimaryHDU(full_image)
hdu.writeto('dark_image.fits', clobber=True)

print Z.max()
print Z.min()

print asdf
