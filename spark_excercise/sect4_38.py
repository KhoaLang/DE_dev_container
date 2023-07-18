import pyspark
from pyspark.sql import SparkSession, functions as func
from pyspark.sql.types import StructField, StructType, StringType, IntegerType

ss = SparkSession.builder.appName('TheMostPopularHeroes').getOrCreate()

schema = StructType([ \
    StructField('id', IntegerType(), True), \
    StructField('name', StringType(), True) \
])

lines = ss.read.text('/workspaces/DE_dev_container/data/Marvel_Graph.txt')

names = ss.read.option('header', 'false').schema(schema).option('sep', ' ').csv('/workspaces/DE_dev_container/data/Marvel_Names.txt')

connections = lines.withColumn('id', func.split(func.col('value'),' ')[0]) \
    .withColumn('connections', func.size(func.split(func.col('value'),' '))-1) \
    .groupBy(func.col('id')).agg(func.sum('connections').alias('connections'))


minConnectionCount = connections.sort(func.col('connections').asc()).first()[1]

# print(minConnectionCount)

minConnectionDF = connections.filter(func.col('connections') == minConnectionCount)

minConnectionDF.show()

name_list = minConnectionDF.join(names, 'id').select('name').show()

