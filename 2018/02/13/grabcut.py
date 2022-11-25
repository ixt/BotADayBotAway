import numpy as np
import cv2
from matplotlib import pyplot as plt

img = cv2.imread('current.png')
mask = np.zeros(img.shape[:2],np.uint8)

bgdModel = np.zeros((1,65),np.float64)
fgdModel = np.zeros((1,65),np.float64)
 
# rect = (50,50,450,290)
rect = (int(img.shape[0]/4),int(img.shape[1]/4),int(img.shape[0]/2),int(img.shape[1]/2))
print(rect)
cv2.grabCut(img,mask,rect,bgdModel,fgdModel,3,cv2.GC_INIT_WITH_RECT)
 
mask2 = np.where((mask==2)|(mask==0),0,1).astype('uint8')
img = img*mask2[:,:,np.newaxis]
 
cv2.imwrite('grabcut.png', img)
