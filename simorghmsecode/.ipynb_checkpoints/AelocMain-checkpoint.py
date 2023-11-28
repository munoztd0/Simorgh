from datetime import datetime,date
import math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy
from collections import Counter
import os
from scipy.signal import (butter, lfilter, hilbert, detrend, periodogram)

from obspy.signal.trigger import (
    ar_pick, classic_sta_lta, classic_sta_lta_py, coincidence_trigger, pk_baer,
    recursive_sta_lta, recursive_sta_lta_py, trigger_onset)

# Assuming 'events' is a 2D NumPy array and 'trigphase' and 'sampphase' are dictionaries of NumPy arrays.
# The dictionaries are indexed by tuples where the first element is the phase number and the second is 'ee'.


def ReadBinary(nam, addr1, addr2, length_of_channel = 40000000):
    """
    Baby describe the function here, here is the doc that appears later. Do not forget the indentation.
    """
        
    length_of_channel = 40000000
    chall = np.empty((2 * len(nam), length_of_channel))
    for f in range(len(nam)):
        if f <= 3 :
            filenam = nam[f]
        else :
            filenam = nam[f]
            
        signal = np.fromfile(filenam, count=- 1, dtype='>i2')
        
        ch1 = signal[1::2]
        ch2 = signal[::2];
    
        
        chall[ 2 * f, : ] = detrend(ch1) #  removing mean and trend
        chall[ 2 * f + 1 , :] = detrend(ch2) #

    
    return chall



