# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# use OS for file IO and the like
import os
# use numpy for array operations
import numpy as np
# Use CSV for writing human readable files
import csv
from scipy.optimize import curve_fit
# path!
import ntpath
# for getting formatted times
import time

# flags for recquiring data
fileFlag="--file"
nFlag="--n"

def digitize(data,maxBins):
    bins,stepSize = smartBins(data,maxBins=maxBins)
    return np.digitize(data,bins,right=True)

def smartBins(data,minStep=None,includeExtraRight=True,maxBins=100):
    # includeExtraRight: if we need to include the 'rightmost bin edge'
    # get the minimum step in the data
    uniVals = np.unique(data)
    if (uniVals.size == 1):
        stepSize = uniVals[0]/2
    else:
        stepSize = min(np.abs(np.diff(uniVals)))
    # threshhold the bins, if we need to, based on a reasonable number
    if (minStep is None and maxBins is not None):
        minStep = (uniVals[-1]-uniVals[0])/maxBins
        stepSize = max(stepSize,minStep)
    minV = np.min(data)
    maxV = np.max(data)
    # create bins of size minSize, including the endpoints
    start = minV-stepSize/2
    end = maxV+stepSize if includeExtraRight else maxV + stepSize/2
    bins = np.arange(start,end,stepSize)
    # return the bins and bin sizes
    return bins,stepSize

def whereclose(arr,val):
    minIdx = np.argmin( np.abs(arr-val) )
    return minIdx,arr[minIdx]

def column_stack(toFlat,filePath = None,labels=None,fmt='%s',delim='\t,\t',
                 comments='#',newline='\n',fillChar=' '):
    # column stacks everything you give it by flattening and
    # then using numpy's column stack
    # fillChar is what we put in the footer and comments if we see the delimiter
    newArr = []
    for arg in toFlat:
        newArr.append(np.array(list(arg),dtype=np.object).flatten())
    arr = np.column_stack(newArr)
    if (filePath is not None):
        if labels is None:
            labels = [str(i) for i in range(len(toFlat)) ]
        # POST: have labels
        header  = delim.join(labels)
        footer = ("(c) Patrick Heenan patrick.raymond.heenan@gmail.com." + 
                  "Generated on {:s}").format(getTimeStamp())
        footer = footer.replace(delim,fillChar)
        comments = comments.replace(delim,fillChar) + newline
        np.savetxt(filePath, arr, fmt=fmt, delimiter=delim,footer=footer,
                   header=header,newline=newline,comments=comments)
    return arr


# Stats
def RSQ(predicted,actual):
    # given predicted and actual values, get the RSQ
    meanObs = np.mean(actual)
    SS_Res = np.sum((predicted-actual)**2)
    SS_Tot = np.sum((actual-meanObs)**2)
    return 1 - SS_Res/SS_Tot

def lineIntersect(slope1,intercept1,slope2,intercept2):
    return (intercept1-intercept2)/(slope2-slope1)

# assumes that aThenBX are lists for the two lines
def lineIntersectParam(aThenB1,aThenB2):
    return lineIntersect(aThenB1[0],aThenB1[1],aThenB2[0],aThenB2[1])


def linModel(xData,a,b):
    # y = ax+b
    return np.array(xData)*a+b

def GenFit(x,y,model=linModel,**kwargs):
    params,Cov = curve_fit(f=model,xdata=x,ydata=y,**kwargs)
    # the square root of the diagonal elements are the standard deviations
    paramsStd = np.sqrt(np.diag(Cov))
    predicted = model(x,*params)
    return params,paramsStd,predicted

def fitInfo(x,y,units=['',''],model=linModel,varStr=['a','b'],
            modelStr="y=a*x+b"
            ,degFit=1,fmtStr=".3g",full=False,simplify=True,**kwargs):
    # get all the information you could want about the fit.
    # XXX TODO: add in support for non linear models.
    # x: observed x
    # y: observed y
    # units: units of the variables in varStr
    # varStr: parameters of the fit. goes from high degree to low 
    # modelStr: describing the model.
    # degFit: degree of the model
    # fmtStr: formating of the data
    # full : if we should return all the data
    params,paramsStd,predicted = GenFit(x,y,model,**kwargs)
    R_SQ = RSQ(predicted,y)
    # if RSQ is very close to 1 (XXX add parameter?) don't display, since
    # we are likely not interested in an actual fit...
    if (not simplify or (R_SQ-1) > 1.e-6):
        modelStr += "\nRSQ: {:.3f}".format(R_SQ)
    for label,mean,stdev,unitTmp in zip(varStr,params,paramsStd,units):
        tempMStr = ("\n{:5s}={:" + fmtStr + "}").format(label,mean)
        # if either in range or told not to simplify, add the stdev
        if (not (np.isfinite(stdev) or stdev<0 or stdev == float('inf'))
            or not simplify):
            tempMStr += "+/-{:.1g}".format(stdev)
        modelStr += tempMStr
        # add the units (if we have any)
        if (len(unitTmp) > 0):
             modelStr += "[{:s}]".format(unitTmp)
    if (full):
        return predicted,modelStr,params,paramsStd,RSQ
    else:
        return predicted,modelStr

def getSanitaryPath(path,includeSep = True):
    # return the sanitized path plus an os-dependent separator,maybe
    toRet =os.path.normpath(path)
    if (includeSep):
        return toRet + os.sep
    else:
        # dont include the separator
        return toRet

def file_name_from_path(path):
    return ntpath.basename(path)
    
def getFileFromPath(path):
    return file_name_from_path(path)

def getBasePath(path):
    return getSanitaryPath(os.path.dirname(path))

def dirExists(directory):
    return os.path.exists(getSanitaryPath(directory))

def makeTrialDir(base,label=None,time=True):
    basePath = getSanitaryPath(base)
    # start the full path just as the base
    fullPath = ensureDirExists(basePath)
    # add if necessary
    if (label is not None):
        fullPath += getSanitaryPath(label)
    if time:
        # add the timestamp, then make sure to add the separator
        fullPath += getTimeStamp() + os.sep
    fullPath = ensureDirExists(fullPath)
    return fullPath

def getTimeStamp(fmt="%d_%m_%Y_%H:%M:%S"):
    """
    Returns: the current time stamp, formatted as fmt
    """
    return time.strftime(fmt)

def ensureDirExists(directory):
    """
    if directory doesnt exist, makes it 

    Args:
        directory: which directory we want 
    Returns:
        the sanitized path name 
    """
    # make the directory if it isn't there!
    sanit = getSanitaryPath(directory)
    if not dirExists(sanit):
        os.makedirs(sanit)
    return sanit

def isfile(filename):
    """
        Returns: true iff filename is actually a file 
    """
    sanit = getSanitaryPath(filename,False)
    return os.path.isfile(sanit)

def ensurePathExists(globalOutput,subPaths):
    ensureDirExists(globalOutput)
    path = globalOutput
    for nextPath in subPaths:
        path += os.sep + nextPath
        path = getSanitaryPath(path)
        ensureDirExists(path)
    return path + os.sep

def getAllFiles(path,ext):
    """
    Gets all files with extension "ext" in path

    Args:
        path: which path
        ext: extension the file must end with
    Returns:
        list of path-appended filenames
    """
    # add the trailing slash
    path = os.path.join(path, '')
    filesRaw = os.listdir(path)
    filesFull = [path + f for f in filesRaw if f.endswith(ext)]
    return filesFull

def humanReadableSave(listToSave,fileName,header):
    # if opening a file object, use newline ='' , according to:
    # https://docs.python.org/3/library/csv.html#id2
    with open(fileName + ".csv","w",newline='') as f:
        writeObj = csv.writer(f)
        # XXX move this? right now, try and catch. prolly should just
        # check if the first element is a list.
        try:
            writeObj.writerows(listToSave)
        except (csv.Error) as e:
            # must not be a list
            writeObj.writerows([listToSave])
                            

def saveAll(matricesToSave,labels,thisPath,saveCSVForHumans=True):
    # matricesToSave: a list of N matrices to save
    # labels: a list of labels to put in the headers of the matrices
    # global output: a single, global output folder
    # thispath: a list of N strings giving sub-folders under the global output 
    path = globalIO.getOutputDir(thisPath)
    for i,mat in enumerate(matricesToSave):
        fName = path + labels[i]
        ReportMessage("Saving " + labels[i])
        np.save(fName,mat)
        # only save CSV is they want it
        if (saveCSVForHumans):
            humanReadableSave(mat,fName,labels[i])
        # XXX: probably want somethng like this 
        # http://stackoverflow.com/questions/14037540/writing-a-python-list-of-lists-to-a-csv-file

def ensureEnds(strV,ext):
    if not (strV.endswith(ext)):
        return strV + ext
    else:
        return strV

def toLatexStr(numpyArr,fmt="{:s}"):
    """
    Returns a numpy array as a string see:
    tex.stackexchange.com/questions/54990/convert-numpy-array-into-tabular
    
    Args:
        the array
    Returns:
        The string to use 
    """
    return " \\\\\n".join([" & ".join( (fmt.format(str(c))
                                        for c in line))
                           for line in numpyArr])
