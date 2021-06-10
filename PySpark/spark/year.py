# Libraries
from pyspark import SparkConf, SparkContext
import sys


# Check that input and output files are specified
if len(sys.argv) != 3:
    print('Usage: ' + sys.argv[0] + ' <in> <out>')
    sys.exit(1)
inputlocation = sys.argv[1]
outputlocation = sys.argv[2]


# Configure PySpark variable
conf = SparkConf().setAppName('WordCount')
sc = SparkContext(conf=conf)


# Actual code
data = sc.textFile(inputlocation)

# split the data ([YYYY-MM-DD, TMAX, TMIN])
data_split = data.map(lambda line: line.split(','))
# get the format of [YYYY, TMAX, TMIN, 1] (1 for 1 element)
data_year = data_split.map(lambda el: [el[0][:4], [int(el[1]), int(el[2]), 1]])
# group by key to have [YYYY, (Iterable <TMAX, TMIN>)]
data_iter = data_year.reduceByKey(lambda x, y: [x[0] + y[0], x[1] + y[1], x[2] + y[2]])
# reduce by key and get values
data_out = data_iter.map(lambda el: [el[0], [el[1][0]/el[1][2], el[1][1]/el[1][2]]])


# Save the output and stop PySpark
data_out.saveAsTextFile(outputlocation)
sc.stop()