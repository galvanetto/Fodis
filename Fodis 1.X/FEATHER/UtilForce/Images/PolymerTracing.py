# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys,scipy,copy


class WormObject(object):
    def __init__(self,x,y,header,file_name,px_to_meters):
        """
        object for keeping track of an x,y trace
        
        Args:
            x,y: the coordinates, in pixels
            file_name: where this trace came from
            image: the image object, for getting dimensions
            header: the header information to store from the file
        """
        self._x = x
        self._y = y
        self.px_to_meters = px_to_meters
        self.file_name = file_name
        self.header = header
    @property
    def x(self):
        return self._x
    @property
    def y(self):
        return self._y
    @x.setter
    def x(self,x):
        self._x = x
    @y.setter
    def y(self,y):
        self._y = y
    @property
    def x_meters(self):
        return self.x * self.px_to_meters
    @property
    def y_meters(self):
        return self.y * self.px_to_meters

class TaggedImage:
    def __init__(self,image,worm_objects):
        """
        Grouping of an images and the associated traces on items
        
        Args:
            image_path: the file name of the image
            worm_objects: list of worm_objects associated with this image
        """
        self.image_path = image.Meta.SourceFile
        self.image = image
        self.worm_objects = worm_objects
    @property
    def Meta(self):
        return self.image.Meta
    @property
    def file_name(self):
        return self.image_path.rsplit("/",1)[-1]
    def subset(self,idx):
        return [copy.deepcopy(self.worm_objects[i]) for i in idx]
