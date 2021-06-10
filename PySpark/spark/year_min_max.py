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

# separate TMAX and TMIN and later join
# get the format of [YYYY, TMAX, day for TMAX] 
data_max = data_split.map(lambda el: [el[0][:4], [int(el[1]), el[0][5:]]])
# get the format of [YYYY, TMAX, day for TMAX] 
data_min = data_split.map(lambda el: [el[0][:4], [int(el[2]), el[0][5:]]])

def larger_element(x, y):
    if x[0] > y[0]:
        return x
    return y

def smaller_element(x, y):
    if x[0] < y[0]:
        return x
    return y

data_max_reduced = data_max.reduceByKey(larger_element)
data_min_reduced = data_min.reduceByKey(smaller_element)

# join 2 RDDs
data_out = data_max_reduced.join(data_min_reduced)

# Save the output and stop PySpark
data_out.saveAsTextFile(outputlocation)
sc.stop()