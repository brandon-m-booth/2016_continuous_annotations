import cy_tste # to install globally, python setup.py build_ext install
import numpy as np
import matplotlib.pyplot as plt

triplets = np.load('triplets.npy').copy(order='C')

X = cy_tste.tste(triplets.astype(int), no_dims=1,lamb=1,alpha=2)

plt.plot(X)
plt.show()