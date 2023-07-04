from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("ReadFromJSON").getOrCreate()

multiline_df = spark.read.option("multiline","true") \
      .json("/workspaces/de-env/dataset/db.json")
multiline_df.show()    

