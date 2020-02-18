from __future__ import division
import numpy as np

def complement(strV):
    dictDNA = {'A':'T',
               'T':'A',
               'G':'C',
               'C':'G'}
    return ''.join([ dictDNA[base] for base in strV ])

def revComp(strV):
    return complement(strV[::-1])

def dilution(stockConc,desiredConc,desiredNg):
    # stockConc: concentration in ng/uL of stock solution
    # desiredConc: "", end result
    # desiredNg: number of nanograms in final solution
    # fix the mass and concentration, give a recquired volume
    volumeStock = desiredNg/stockConc
    otherVolume = (stockConc*volumeStock)/desiredConc-volumeStock
    return volumeStock,otherVolume

def gelVolumesFromNanodropFile(fileName,desiredNg=8000,desiredDilution=50,
                               lbRatio=5,idxOffset=1,printMe=True,
                               skipFirst=1,skipLast=1):
    data = np.genfromtxt(fileName,dtype=np.object)
    concCol = 6
    concArr = [float(f) for f in data[:,concCol]]
    concs = np.array(concArr)
    concs = concs[skipFirst:len(concArr)-skipLast]
    return getVolumesFromData(concs,desiredNg,desiredDilution,lbRatio,idxOffset,
                              printMe,skipFirst,skipLast)

def getVolumesFromData(concs,desiredNg=8000,desiredDilution=50,
                       lbRatio=5,idxOffset=1,printMe=True,
                       skipFirst=1,skipLast=1):
    # file: nanodrop file 
    # desired ng: number of nanograms
    # desired dilution: ng/uL
    # lbRatio: 5
    # idxOffset: for printing, how to offset (sample0 --> sample 1)
    # printme: print the data you need
    desiredConc = np.mean(concs) # XXX assume we want the mean concentration
    sortIdx = np.argsort(concs)
    concs = np.array(concs[sortIdx])
    num = len(concs)
    targets = concs-desiredConc
    newConc = np.zeros(num)
    vDNA = np.zeros(num)
    lbVol = np.zeros(num)
    teVol = np.zeros(num)
    for i,t in enumerate(targets[:np.ceil(num/2)]):
        oIdx = -(i+1)
        newConc[i] = (concs[i] + concs[oIdx])/2
        vDNA[i],otherVolume = dilution(newConc[i],desiredDilution,desiredNg)
        lbVol[i] = vDNA[i]/lbRatio
        teVol[i] = otherVolume-lbVol[i]
        if (printMe):
            print(("Add {:d}[{:.2f}ng/uL] to {:d}[{:.2f}ng/uL], take {:.2f}uL "+
                   "of the {:.2f}ng/uL solution, " +
                   "{:.3f}uL of loading buffer, and {:.2f}uL of TE. Run.").\
                  format(sortIdx[i]+idxOffset,concs[i],
                         sortIdx[num+oIdx]+idxOffset,concs[num+oIdx],vDNA[i],
                         newConc[i],lbVol[i],teVol[i]))
    return newConc,vDNA,lbVol,teVol

# constants defined for weighing
amu_kg =  1.66e-27
#https://www.neb.com/tools-and-resources/usage-guidelines/nucleic-acid-data
dsDNAPerBP_kg = 650 * amu_kg # weight of a base par

def getBPWeightKg(bp):
    return dsDNAPerBP_kg * bp

