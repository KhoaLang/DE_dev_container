import pyspark
from pyspark.sql import SparkSession, functions as func
from pyspark.sql.types import StructField, StructType, StringType, IntegerType

ss = SparkSession.builder.appName('TheMostPopularHeroes').getOrCreate()

schema = StructType([ \
    StructField('id', IntegerType(), True), \
    StructField('name', StringType(), True) \
])

lines = ss.read.text('/workspaces/DE_dev_container/data/Marvel_Graph.txt')

df_mv_name = ss.read.option('header', 'false').schema(schema).option('sep', ' ').csv('/workspaces/DE_dev_container/data/Marvel_Names.txt')

connections = lines.withColumn('id', func.split(func.col('value'), " ")[0]) \
    .withColumn('connections', func.size(func.split(func.col('value'), ' ')) - 1) \
    .groupBy('id').agg(func.sum('connections').alias('connections'))
    

connections.show()

most_pop_id=connections.sort(func.col('connections').desc()).first()

most_pop_name = df_mv_name.filter(func.col('id') == most_pop_id[0]).first()
print(most_pop_name)
# lines.show()