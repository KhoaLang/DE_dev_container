import pyspark
from pyspark.sql import SparkSession, functions as func

spark = SparkSession.builder.appName("FriendsByAge").getOrCreate()

line = spark.read.option("header", "true").option("inferSchema", "true")\
    .csv("/workspaces/de-env/fakefriends-header.csv")

line.select("age", "friends")
# line.groupBy("age").avg("friends").show()

# line.groupBy("age").agg(func.round(func.avg("friends"),2)).show()
line.groupBy("age").agg(func.round(func.avg("friends"),2).alias("friendsByAge")).sort("age").show()

