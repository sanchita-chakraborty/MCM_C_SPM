import numpy as np
from numpy import genfromtxt
import scipy
import csv
import matplotlib.pyplot as plt

# read data
print("about to start loading")
chain_data = genfromtxt('BCHAIN-MKPRU.csv', delimiter=',')
# gold_data = genfromtxt('LBMA-GOLD.csv', delimeter=',')
print("loaded")
print(type(chain_data))
plt.plot(chain_data)
plt.show()
