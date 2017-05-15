#!/usr/bin/python

import os
import pdb
import cv2
import csv
import math
import numpy as np

def MakeFrame(red, green, blue, width_height):
   img = np.ones((width_height[1], width_height[0], 3))
   img[:,:,0] *= red
   img[:,:,1] *= green
   img[:,:,2] *= blue
   return img.astype(np.uint8)

def DoCreateVideo():
   progress_every_percent = 10
   max_channel_value = 255.0
   video_length_seconds = int(60*2.98)
   frame_rate = 30.0
   width_height = (853,480)
   out_file_path = 'Bluer.mp4'
   out_csv_path = 'Bluer.csv'
   wav1_freq = 0.15
   wav2_freq = 0.06
   wav1_amp = 0.1
   wav2_amp = 0.3
   total_amp = wav1_amp+wav2_amp
   #codec = cv2.VideoWriter_fourcc(*'X264')
   codec = 0x21 # The fourcc code for H264 throws errors for mp4, but this value works...
   out_video = cv2.VideoWriter(out_file_path, codec, frame_rate, width_height, True)

   if out_video.isOpened():
      with open(out_csv_path, 'wb') as csvfile:
         csv_writer = csv.writer(csvfile, delimiter=',')
         csv_writer.writerow(['Time(sec)','Data'])
      
         video_frames = int(video_length_seconds*frame_rate)
         for i in range(video_frames):
            if i%(video_frames/progress_every_percent) == 0:
               print '%f percent complete...'%(100*float(i)/video_frames)
            green = wav1_amp/total_amp*0.4*(math.sin(i*wav1_freq*2.0*math.pi/frame_rate))+0.4
            green += wav2_amp/total_amp*0.4*math.sin(i*wav2_freq*2.0*math.pi/frame_rate)
            frame = MakeFrame(0.0, green*max_channel_value, 0.0, width_height)
            csv_writer.writerow([i/frame_rate, green])
            out_video.write(frame)

      out_video.release()

   return

if __name__=='__main__':
   DoCreateVideo()
