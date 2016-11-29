#!/usr/bin/python

#########################################################################################
#    mileage.py - 8/1/2016 - Otto Leichliter                                            #
#    graph the MPG for each tank of gas + running total MPG & average of total MPGs     #
#    can also output a table of the data (see below for example)                        #
#########################################################################################

# import stuff we need
import os
import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
from matplotlib import style
import matplotlib.patches as mpatches
from matplotlib.font_manager import FontProperties
font = FontProperties()
font.set_family('monospace')
font.set_size('x-large')
font.set_size('small')
fig = plt.figure(figsize=(8, 5), dpi=200)						# define plot size in inches (width, height) & resolution(DPI)
os.chdir( "/home/ottol/mileage/" )							# where the files are


# read data file
a = open('mileage.out', 'r').readlines()						# space delimited text file of consecutive fillups [gallons odometer]
l = len( open('mileage.out', 'r').readlines() )						# l = # of lines in file
print 'l='+str(l)
med = open( 'med.out', 'r' ).readlines()						# read then median value
mvs = open( 'mvs.out', 'r' ).readlines()						# read sequence of median values
mvl= len( open( 'mvs.out', 'r' ).readlines() )
print 'mvl='+str(mvl)

# declare lists
y1 = []											# list for average mpg since last fill up
y2 = []											# list for will be total average from first record kept
x  = []											# list for  odometer reading for the above 2 averages
al = []											# average of total averages above
y3 = []											# flat line last average of total averages
y4 = []

# declare axes and set colors
ax = plt.gca()
ax.tick_params(axis='x', colors='k')							# x-axis black
ax.tick_params(axis='y', colors='k')							# y-axis black


# create lists for graphs
for i in range(l):
	if ( i > 0 ):
		gas,miles,delta,dmpg,tmpg,atmpg = a[i].rstrip().split()
		y1.append(float(dmpg))
		y2.append(float(tmpg))
#		al.append(float(atmpg))
		x.append(int(miles))
atmpg = 39.6
for i in range(l):
	if ( i > 0 ):
		y3.append(float(med[0]))
		j=i-1
		print i, j
		if ( j != l ):
			y4.append(float(mvs[j]))
#		y4.append(float(tmpg))

# now create graphs
# default colors:  'b'=blue  'g'=green  'k'=black  'r'=red
# plot graphs
plt.plot(x,y1,'b',linewidth=1,marker="+")						# plot the single tank MPGs
plt.plot(x,y2,'g',linewidth=1,marker="+")						# plot the running total MPGs
#plt.plot(x,al,'-r',linewidth=1,marker="+")						# plot the average of running totals
plt.plot(x,y3,'-r',linewidth=1)								# draw horizontal line at ending average of totals
plt.plot(x,y4,'-r',linewidth=1)
plt.axis(color='k')									# set the axis color

# set & color axis labels
plt.ylabel('M.P.G.',color='k')
plt.xlabel('Odometer',color='k')

# create legend showing which graph is what
# blueData  = mpatches.Patch(color='b', label='One fillup to the next')
# greenData = mpatches.Patch(color='g', label='OverAll = '+ str(tmpg) )
# redData   = mpatches.Patch(color='r', label='Average of OverAll = '+ str(atmpg) )
blueData  = mpatches.Patch(color='b', label='Tank:      '+ str(dmpg) )
greenData = mpatches.Patch(color='g', label='AMPG:    '+ str(tmpg) )
redData   = mpatches.Patch(color='r', label='Median:  '+ str(med[0].rstrip()) )
leg = plt.legend(handles=[blueData,greenData,redData], loc=2)					# location 2 = top left
#leg = plt.legend(handles=[blueData,greenData], loc=2)					# location 2 = top left
leg.get_frame().set_alpha(0.5)

# Title and grid lines color
plt.title('Prius Gas Mileage')
plt.grid(True,color='k')

# plt.show()										# show graphs
fig.savefig('/home/ottol/mileage.png', bbox_inches='tight' )				# save graphs as png
