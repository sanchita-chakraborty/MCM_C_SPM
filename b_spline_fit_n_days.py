# import numpy as np
# import scipy
import matplotlib.pyplot as plt

from scipy.interpolate import BSpline
from numpy import genfromtxt

def bspline_fit(data, n_days):
    days = list(range(n_days))
    spline = BSpline(days, data, 4, extrapolate=True)
    print(str(spline))
    return spline(n_days-4)


#testing function here
day_num = 20
print("ABOUT TO LOAD")
chain_data = genfromtxt('BCHAIN-MKPRU.csv', delimiter=',')
today = chain_data[day_num-1,1]
print("today is " + str(today))
next_day = bspline_fit(chain_data[:day_num,1], day_num)
print("tomorrow is " + str(next_day))
print(len(chain_data[:day_num,1]))

# ax.plot(xx, [bspline(x, t, c ,k) for x in xx], 'r-', lw=3, label='naive')
# ax.plot(xx, spl(xx), 'b-', lw=4, alpha=0.7, label='BSpline')
# ax.grid(True)
# ax.legend(loc='best')
# plt.show()
