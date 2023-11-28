#!/usr/bin/env python
# coding: utf-8


from datetime import datetime, date

import datetime
import math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
import os
import operator
import sys
import glob
import shutil

from scipy.signal import (butter, lfilter, hilbert, detrend, periodogram)
from scipy.io import loadmat
from shutil import make_archive

from mpl_toolkits.mplot3d import Axes3D
from pylab import *
from obspy.signal.trigger import (
    ar_pick, classic_sta_lta, classic_sta_lta_py, coincidence_trigger, pk_baer,
    recursive_sta_lta, recursive_sta_lta_py, trigger_onset)
import simorghMSEmodule



accountname = sys.argv[1]
projectnamecode = sys.argv[2]
industrytype = sys.argv[3]
calctype = sys.argv[4]




clientInfoPath_= './simorghmse/' , projectnamecode , '/' , accountname , '-' , industrytype , '-' , calctype , '.csv'
clientInfoPath = ''.join(clientInfoPath_)



clientInfo = pd.read_csv(clientInfoPath, index_col=0)






resultsfoldname = '-'.join([accountname, projectnamecode, industrytype, 'results'])



# Set your parameters here
hr1, hr2 = 18, 18
min1, min2 = 19, 19
sec1, sec2 = 10, 14
datenam = [2022, 4, 7]
rocknam = 'Gabbro07K'
starttime = [hr1, min1, sec1]
endtime = [hr2, min2, sec2]


length_of_channel = 40000000



velocityPath_= ['./simorghmse/', projectnamecode, '/velocitymodel.txt']
velocityPath = ''.join(velocityPath_)
velocitymodel = pd.read_csv(velocityPath, header=None, delimiter="\t")  



sensorsPath_= ['./simorghmse/', projectnamecode, '/sensors.txt']
sensorsPath = ''.join(sensorsPath_)
receivers = pd.read_csv(sensorsPath, header=None, delimiter="\t")   
receivers = receivers * 100
len_receivvers = len(receivers)


Vp=velocitymodel.iloc[0].iloc[0]



datetime.datetime.now().strftime('%H:%M:%S')

# Create results folder if it doesn't exist
#if not os.path.exists(resultsfoldname):
#    os.mkdir(resultsfoldname)

#parall = val  # p-wave velocity m/s from active acoustic
# Other parameters can be loaded similarly

# Initialize other variables
figsignal, figrms, wavesave = 0, 0, 0
risedurfrac = 1200
threshold_hits = 100
threshold_rise = 100
noise_thresh_rise = 10
amp_dur_thresh = 50
rng1, rng2, rng3 = 25, 25, 25
TIHOM=0


# rng1, rng2, rng3, receivers, TIHOM, and Vp are already defined

# Initialize the lists to store distances and times
distAEs = [[[[0 for _ in range(len(receivers))] for _ in range(rng3)] for _ in range(rng2)] for _ in range(rng1)]
timeAEs = [[[[0 for _ in range(len(receivers))] for _ in range(rng3)] for _ in range(rng2)] for _ in range(rng1)]

# Loop over the ranges 
for i in range(rng1):
    for j in range(rng2):
        for k in range(rng3):
            for r, receiver in enumerate(receivers):
                # Calculate the norm (distance) between [i+1, j+1, k+1] and receiver
                # Adding 1 to each index since MATLAB is 1-indexed and Python is 0-indexed
                dist = np.linalg.norm(np.array([i+1, j+1, k+1]) - np.array(receiver))
                distAEs[i][j][k][r] = np.float32(dist)
                
                if TIHOM == 1:  # for TI material
                    theta = math.atan2(abs(j+1-receiver[1]), i+1-receiver[0]) * (180 / math.pi)
                    Vp = PhaseVel(theta)  # Assuming PhaseVel is a defined function
                    
                # Calculate time, converting cm to meters by dividing by 100
                timeAEs[i][j][k][r] = np.float32(dist / 100 / Vp)

# At this point, distAEs and timeAEs are 4D lists populated with distances and times




AA= ['./simorghmse/',projectnamecode,'/']
AAjoined = ''.join(AA)
startpart=str(datenam[0]) + '-' + ('{0:0=2d}'.format(datenam[1])) + '-' + ('{0:0=2d}'.format(datenam[2])) + '_' + ('{0:0=2d}'.format(starttime[0]))  + '-' +  ('{0:0=2d}'.format(starttime[1])) +  '-' +  ('{0:0=2d}'.format(starttime[2])) +  '.2215332_'  + rocknam  + '_ch*'

nam=sorted(glob.glob(AAjoined+startpart))
passivehour = float(startpart[11:13]) 
passivemin = float(startpart[14:16])
passivesec = float(startpart[17:19])


chall = simorghMSEmodule.ReadBinary(nam, AAjoined,AAjoined)


os.chdir(AAjoined)
os.makedirs(resultsfoldname, exist_ok=True)
os.chdir(resultsfoldname)


resultsfoldpath = os.getcwd()



current_date = date.today().strftime("%b-%d-%Y")
current_time = datetime.datetime.now().strftime("%H:%M:%S") # clo
starttime = [hr1, min1, sec1]
endtime = [hr2, min2, sec2]

starttime_str = ''.join([str(i) for i in starttime])
endtime_str = ''.join([str(i) for i in endtime])

#np.timedelta64(starttime)
A = [ 2022, 4, 7]
datename = ''.join([str(i) for i in A])



directory_path = '/'.join([resultsfoldname, 'ResultsActivetime'])


activetimename = '-'.join([ 'activetime', datename, starttime_str, current_time])
activetimename = ''.join(['/ResultsActivetime/',activetimename, '.txt'])


datalength = 4
fracsamp = (len(chall[1])/(datalength))/2e6 # fraction for sample convertion to detect the signals
samprate = fracsamp*2e6 # fix(sampnumb/(2*datalength)); 2 channnels and 4 seconds
date = str(startpart[0:10])
time=str(startpart[11:19])


Fs = samprate
filtlengthstep = samprate/100 # % steps for calculation of fourier spectrum
activecorrTDFD = 1
activecorrTD = 0
activecorrFD = 1

#activetimename = 'activetime' + date + time + str(current_date) + str(current_time) + '.txt'
ActivePowerThreshold = 500
filtlengthstep = 1e5


# mainloo = 1
mainloo, rocknam = 1, "Gabbro07K"


# Parsing dates and times
year = int(date[:4])
month = int(date[5:7])
day = int(date[8:10])
hour = int(time[:2])
minute = int(time[3:5])
second = int(time[6:8])



# Filter requirements.
T = 4.0           # Sample Period
fs = 1e7          # sample rate, Hz
lowcut = 1e3      # desired cutoff frequency of the filter, Hz, slightly higher than actual 1.2 Hz
highcut = 1e6     # desired cutoff frequency of the filter, Hz, slightly higher than actual 1.2 Hz
nyq = 0.5 * fs    # Nyquist Frequency
order = 2         # sin wave can be approx represented as quadratic
n = int(T * fs)   # total number of samples



if clientInfo.iloc[3].iloc[0]=='realtime':
    realtime = True
else:
    realtime = False


#realtime = True


# The main loop
usedSTA ={}
A = '-'.join([clientInfo.iloc[0].iloc[0], clientInfo.iloc[1].iloc[0], clientInfo.iloc[2].iloc[0], 'visualization']) +'.png'
figpath = '-'.join([clientInfo.iloc[0].iloc[0], clientInfo.iloc[1].iloc[0], clientInfo.iloc[2].iloc[0], 'visualization']) +'.html'


x, passive_plot_cnt = 0, 0
TimeToPlot = 0

sec_start = datetime.datetime.now().second
min_start = datetime.datetime.now().minute
h_start = datetime.datetime.now().hour

file_stop_name_= ['./simorghmsecode/', projectnamecode, '-stop.txt']
file_stop_name = ''.join(file_stop_name_)

loopend=10
for phasenum in range(loopend):
        
        if os.path.exists(file_stop_name)== False:
            #loopend=phasenum
            sec_end = datetime.datetime.now().second
            min_end = datetime.datetime.now().minute
            h_end = datetime.datetime.now().hour
            
            if h_end >= h_start :
                T = (h_end - h_start) * 60 + (min_end - min_start)
            else:
                T = (h_end + 24 - h_start) * 60 + (min_end - min_start)
        
            if (realtime == False) &  ( T >= TimeToPlot)  & (passive_plot_cnt == 0 ):
                #print(realtime, T,passive_plot_cnt)
                x = x+1
                fig, ax = plt.subplots(1, 1)
                ax.plot(chall[7])
                ax.set_title('fig1', size= 15)
                fig1 = plt.gcf()
                fig1.savefig(A, dpi=100)
                fig1.savefig('fig-first.png', dpi=100)
                passive_plot_cnt = 1
        
            if (realtime == True) & ( phasenum%3 == 0) :
                fig, ax = plt.subplots(1, 1)
                ax.plot(chall[7])
                ax.set_title(phasenum, size= 15)
                x = x+1
                fig1 = plt.gcf()
                fig1.savefig('phasenum %d' %phasenum, dpi=100)
                fig1.savefig(A, dpi=100)
            
            with open('estimated_remaining_time.txt', 'w') as ff:
                estimated_remaining_time = 1000 - phasenum
                #ff.write(str(estimated_remaining_time))
                #ff.write("\n")
                ff.write(datetime.datetime.now().strftime('%H:%M:%S'))
                ff.write("\n")

if realtime == False :
        
        fig, ax = plt.subplots(1, 1)
        ax.plot(chall[7])
        ax.set_title('fig-end', size= 15)
        fig1 = plt.gcf()
        
        fig1.savefig(A, dpi=100)
        fig1.savefig('fig-end.png', dpi=100)

    
        

        

#to create results folder in zip
make_archive(resultsfoldpath, 'zip', resultsfoldpath)





