# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
pipe_fileIdx = 0
pipe_funcIdx = 1

from . import GenUtilities as pGenUtil
import numpy as np
try:
    import cPickle
    kw_load = dict()
except ImportError:
    import _pickle as cPickle
    kw_load = dict(encoding='latin1')


from scipy.sparse import csc_matrix



def getCheckpoint(filePath,orCall,force,*args,**kwargs):
    """
    gets cache data from a previous checkpoint

    Args:
        filePath : path to look for the checkpoint (created at the end
        orCall: function to call if the file isnt there
        force: if true, calls the funciton always (refreshes cache)
        *args : args for the function 'orCall'
        **kwargs: args for the function 'orCall'
    
    Returns:
       Whatever 'orCall' returns, or the cache.
    """
    # use the npz fil format, unpack arguments in the order they
    # are returned by 'orCall'. most 'intuitive', maybe less flexible
    print('Checkpoint: {:s} via {:s}'.format(filePath,str(orCall)))
    return _checkpointGen(filePath,orCall,force,True,False,*args,**kwargs)

def _npyLoad(filePath,unpack):
    data  = np.load(filePath)
    if (unpack == True):
        keys = sorted(data.keys())
        # return either the single element, or the in-save-order list
        if (len(keys)) == 1:
            return data[keys[0]]
        else:
            return tuple(data[key] for key in keys)
    else:
        return data

def _npySave(filePath,dataToSave):
    if (type(dataToSave) is tuple):
        np.savez(filePath,*dataToSave)
    else:
        np.savez(filePath,dataToSave)

def lazy_reload(file_path,data,force):
    """
    this is a way of caching data, or reading the cached data out if it 
    already exists
    
    Args:
        see getCheckpoint
    Returns:
        see getCheckpoint
    """
    data_func = lambda *args,**kwargs: data
    return getCheckpoint(file_path,orCall=data_func,force=False)
    

     
def lazy_save(file_path,data):
    return saveFile(file_path,data,useNpy=False)

def lazy_load(file_path):
    assert pGenUtil.isfile(file_path) , \
        "File {:} doesn't exist".format(file_path)
    return loadFile(file_path,useNpy=False)
        
def saveFile(filePath,dataToSave,useNpy):
    path = pGenUtil.getBasePath(filePath)
    pGenUtil.ensureDirExists(path)
    # need to figure out if we need to unpack all the arguments..
    if (useNpy):
        _npySave(filePath,dataToSave)
    else:
        # open the file in binary format for writing
        if (not filePath.endswith(".pkl")):
            filePath = filePath + ".pkl"
        with open(filePath, 'wb') as fh:
            # XXX make protocol specifiable?
            cPickle.dump(dataToSave,fh,cPickle.HIGHEST_PROTOCOL)

def loadFile(filePath,useNpy):
    """
    
    Args:
        filePath: where the file to load is
        useNpy: if true, tries to load a number obbject
    Returns;
        the cached file if it exists, otherwise throws an error 
    """
    # assuming file exists, loads it. God help you if you dont check existance
    if (useNpy):
        return _npyLoad(filePath,unpack)
    else:
        # assume we pickle in binary
        with open(filePath, 'rb') as fh:
            data = cPickle.load(fh,**kw_load)
        return data
        
def lazy_multi_load(cache_dir,load_func=None,**kw):
    return multi_load(cache_dir,load_func=load_func,**kw)
        
def multi_load(cache_dir,load_func,force=False,limit=None,ext=".pkl",
               name_func=lambda i,o,*args,**kw: "{:d}".format(i)):
    """
    Returns the cached values if we can, otherwise re-runs load_func and returns
    everything
    
    Args:
        cache_dir: where to cache things
        load_func: functor (no arguments; ~lambda function), returns a list
        of instances to cache out/return
        
        force: if true, force re-loading
        limit: maximum number to return. Caches everything it can 
        name_func: takes in iteration number, object, returns string for file 
                   name
     
    Returns:
        at most limit objects, from the cache if possible 
    """
    pGenUtil.ensureDirExists(cache_dir)
    files = sorted(pGenUtil.getAllFiles(cache_dir,ext=ext))
    # if the files exist and we aren't forcing 
    if (len(files) > 0 and not force):
        return [lazy_load(f) for f in files[:limit]]
    # get everything
    examples = load_func()      
    to_ret = []    
    # use enumerate to allow for yield (in case of large files/large numbers)
    for i,e in enumerate(examples):
        if (i == limit):
            break    
        name = "{:s}{:s}.pkl".format(cache_dir,name_func(i,e))
        lazy_save(name,e)
        to_ret.append(e)        
    return to_ret 
    
def _checkpointGen(filePath,orCall,force,unpack,useNpy,*args,**kwargs):
    """
    this is a way of caching data, or reading the cached data out if it 
    already exists
    
    Args:
        see getCheckpoint, except:
        unpack: if we should unpack the data    
        useNpy: if numpy should be used
        *args,**kwargs: passedd to orCall if the file doesnt exist
    Returns:
        see getCheckpoint
    """
    # XXX assume pickling now, ends with 'npz'
    # if the file from 'filePath' exists and 'force' is false, loads the file
    # otherwise, calls 'orCall' and saves the result. *args and **kwargs
    # are passed to 'orCall'.
    # 'Unpack' unpacks the array upon a load. This makes it 'look' like a 
    # simple function call (returns the args, or a tuple list of args)
    # use unpack if you aren't dealing with dictionaries or things like that
    if pGenUtil.isfile(filePath) and not force:
        return loadFile(filePath,useNpy)
    else:
        # couldn't find the file.
        # make sure it exists
        # POST: we can put our file here
        dataToSave = orCall(*args,**kwargs)
        # save the data, so next time we can just load
        saveFile(filePath,dataToSave,useNpy)
        return dataToSave


def _pipeHelper(objectToPipe,force,useNpy,otherArgs = None):
    # sets up all the arguments we need. 
    args = []
    # add all the arguments we need
    if (otherArgs is not None):
        # XXX this might not work so well with multiple arguments
        # passing betwene them.
        if (not (isinstance(otherArgs, (list,tuple)))):
            # if we have some thing which is not a list or a tuple, just add
            args.append(otherArgs)
        else:
             # otherwise, add elements one at a time.
            args.extend(otherArgs)
    customArgs = objectToPipe[pipe_funcIdx+1:]
    if (len(customArgs) > 0):
        for cArg in customArgs:
            args.append(cArg)
    # POST: have all the arguments we need in 'args'
    return _checkpointGen(objectToPipe[pipe_fileIdx],
                          objectToPipe[pipe_funcIdx],
                          force,True,useNpy,
                          *args)

def _pipeListParser(value,default,length):
    if value is None:
        safeList= [default] * length
    elif type(value) is not list:
        safeList = [value] * length
    else:
        # must be a non-None list
        return value
    return safeList 

def pipeline(objects,force=None):
    # objects are a list, each element is : [<file>,<function>,<args>]: 
    # file name,
    # function then the ('extra' args the funcion
    # needs. we assume that each filter in the pipeline takes
    # the previous arguments, plus any others, and returns the next arg
    # the first just takes in whatever it is given, the last can return anything
    # in other words, the signatures are:
    # f1(f1_args), returning f2_chain
    # f2(f2_chain,f2_args), returning f3_chain
    # ...
    # fN(fN_chain,fNargs), returning whatever.

    filesExist = [pGenUtil.isfile(o[pipe_fileIdx]) for o in objects]
    numObjects = len(objects)
    # get a list of forces
    force = _pipeListParser(force,False,numObjects)
    # get a list of how to save.
    numpy = [ not o[pipe_fileIdx].endswith('.pkl') for o in objects] 
    # by default, if no force arguments passed, assume we dont want to force
    # in other words: just load by default
    runIfFalse = [ fExists and (not forceThis)  
                 for fExists,forceThis in zip(filesExist,force)]
    if (False not in runIfFalse):
        # just load the last...
        otherArgs = _pipeHelper(objects[-1],False,numpy[-1])
    else:
        # need to run at least one, go through them all
        otherArgs = None
        firstZero = runIfFalse.index(False)
        # if not at the start, load 'most downstream'
        if (firstZero != 0):
            idx = firstZero-1
            otherArgs = _pipeHelper(objects[idx],
                                    force[idx],numpy[idx],
                                    otherArgs)
        # POST: otherargs is set up, if we need it.
        for i in range(firstZero,numObjects):
            otherArgs = _pipeHelper(objects[i],force[i],numpy[i],otherArgs)
    return otherArgs

