 nn=200
 x=FIndGen(nn)/Float(nn-1)*4
 x=x-2
 
 y0 = 0.11*x + 1.0
 y1 = Voigt1(x,[10,-0.5,0.1,0.5])
 y2 = Voigt1(x,[10,0,0.2,0.3])
 y3 = Voigt1(x,[10,0.5,0.4,0.0])
 y=y0+y1+y2+y3
 yran=max(y) - min(y)
 yran = (yran * 0.05)*randomu(seed,nn)
 y=y+yran
 
 ;
 ; calls PeakFinder
 ;
 pcutoff=0 & CLimits=0 & npeaks=0
 a=PeakFinder(y,x,PCutoff=pcutoff,CLim=CLimits,NPeaks=npeaks,/Sort,/Opt)
 
 ;
 ; Display/plot results
 ;
 Print,'Peaks found: ',N_Elements(a[0,*])
 Print,'Good Peaks: ',nPeaks
 Print,'cutoff value: ',climits[0]
 Print,'confidence value: ',climits[1]
 Plot,x,y,linestyle=1
 OPlot,a[1,*],a[2,*],PSym=1
 OPlot,a[1,0:npeaks-1],a[2,0:npeaks-1],PSym=6
 
 end