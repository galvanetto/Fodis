# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys

def _fix_string(n,list_v):
    """
    Assuming we want a list of length n, convert string,list, or tuple
    list_v into such
    :param n: desired length
    :param list_v: list or tuple (length 1 or N) or string to get N of. If
    the list just has one element, then repeats it N times.
    :return: updated list. Throws error if something bad happens
    """
    if (isinstance(list_v,list) or isinstance(list_v,tuple)):
        n_list = len(list_v)
        if (n_list == 1):
            return [list_v[0] for _ in range(n)]
        else:
            assert n_list == n , "Didn't provide correct number of labels"
            return list_v
    elif (isinstance(list_v,str) or isinstance(list_v,unicode)):
        return [list_v for _ in range(n)]
    else:
        assert False, "Didnt understand input: {:s}".format(list_v)


class SaveRecord(object):
    def __init__(self,x,y,save_name,x_name,x_units,y_name,y_units):
        """

        :param x/y: arrays of data. should be like CxN, where C is the number
        of columns and N is the number of data points. Note that C_x and C_y
        can be different, but N should be the same (one is OK). e.g.
        x = [ [1,2,3],[4,5,6]] and
        y=[ [7,8,9] ]

        would be fine (C_x=2, C_y=1, N=3)

        :param save_name: what to save this out as (less file extension
        :param <x/y>_<name/units>: list, tuple (size N or 1) or single string
        of x and y names and units
        """
        # save x
        x = np.array(x)
        y = np.array(y)
        assert len(x.shape) < 3 , "only support 2-D saving"
        assert len(y.shape) < 3 , "only support 2-D saving"
        n_x = x.shape[-1]
        n_y = y.shape[-1]
        assert n_x == n_y , "Can't save out this data, the columns don't match"
        # POST: columns match
        # make into column arrays
        self.save_name = save_name
        self.x = x.reshape(-1,n_x)
        self.y = y.reshape(-1,n_x)
        # make sure all the meta information is correct
        self.x_name = _fix_string(self.n_x,x_name)
        self.x_units = _fix_string(self.n_x,x_units)
        self.y_name = _fix_string(self.n_y,y_name)
        self.y_units = _fix_string(self.n_y,y_units)
        # POST: <x/y>_<units/name> are all of the appropriate length
    @property
    def n_y(self):
        return self.y.shape[0]
    @property
    def n_x(self):
        return self.x.shape[0]

def _name_format(record,is_x,i):
    """
    Returns: the units associated with records <x/y> values, iff <is_x=T/F>
    """
    name = record.x_name if is_x else record.y_name
    units = record.x_units if is_x else record.y_units
    return "{:s} ({:s})".format(name[i],units[i])
            
def _header(record,comment="#",newline = "\n"):
    """
    Returns: the header associated with the given record 
    """
    join_str_header = ",\t"
    names_x = [_name_format(record,is_x=True,i=i) for i in range(record.n_x)]
    names_y = [_name_format(record,is_x=False,i=i) for i in range(record.n_y)]
    line_labels = join_str_header.join([join_str_header.join(names_x), \
                                       join_str_header.join(names_y)])
    lines = ["(c) Patrick Heenan "] + [line_labels]
    # add the comment string infront of each line
    for i,_ in enumerate(lines):
        lines[i] = comment + lines[i]
    # add the newline character 
    to_ret = newline.join(lines) + newline
    # remove any commas, to prevent problems for csv
    to_ret.replace(",",";")
    return to_ret
    
def _data(record,**kw):
    """
    Returns: the data of record, formatted for immediately saving in-place
    """
    x = [x for x in record.x]
    y = [y for y in record.y]
    return np.vstack((x,y)).T
        
def _csv_save_base(fname,X,header,fmt=str("%-11.10e"),
                   delimiter=",",newline="\n"):
    """
    saves the array X out to the file name specified. See np.savetxt
    """
    np.savetxt(fname,X=X,header=header,fmt=fmt,delimiter=delimiter,
               newline=newline)
        
def _save_to_csv(record,header_kwargs=dict(),data_kwargs=dict(),
                 save_kwargs=dict()):
    header = _header(record,**header_kwargs)
    data = _data(record,**data_kwargs)
    fname = record.save_name + ".csv"
    _csv_save_base(fname=fname,X=data,header=header)
    
def save_csv(record_kwargs=dict(),**kw):
    record = SaveRecord(**record_kwargs)
    _save_to_csv(record,**kw)
    