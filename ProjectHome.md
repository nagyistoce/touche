**Touché** is a free, open-source tracking environment for optical multitouch tables (FTIR, DI, Lasers). It has been written for MacOS X Leopard and uses many of its core technologies, such as QuickTime, Core Animation, Core Image and the Accelerate framework, but also high-quality open-source libraries such as libdc1394 and OpenCV, in order to achieve good tracking performance.

The Touché environment consists of two parts: A standalone tracking application written in Cocoa, that comes with lots of configuration options as well as calibration and test tools, and a Cocoa framework that can be embedded into custom applications in order to receive tracking data from the tracking application. This way, you can easily experiment with MacOS X technologies such as Core Animation or Quartz Composer on your multitouch table.

Key features include a powerful filter pipeline, an easy-to-use embeddable framework to communicate with the tracker, and output of tracking data via the TUIO protocol, as well as direct output of tracking data to Flash applications.


---


**Touchsmart TUIO** is a bridge application for Windows XP/Vista, which can output touch data from Nextwindow API-compatible touch screens in the same formats like Touché. Nextwindow screens are used, among others, on HP Touchsmart PCs.