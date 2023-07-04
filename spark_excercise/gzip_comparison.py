import pyspark
from pyspark.sql import SparkSession, functions as func
import time

gzip_path = "/workspaces/de-env/dataset/01-12/TFTP.csv.gz"
norm_path = "/workspaces/de-env/dataset/01-12/TFTP.csv"
spark = SparkSession.builder.appName("Gzip Comparison").getOrCreate()

start_gzip = time.time()

# df_zip = spark.read.option("header", "true") \
#     .option("inferSchema", "true") \
#     .csv(gzip_path)

# end_gzip = time.time()

# ******************************

start_norm = time.time()

df_norm = spark.read.option("header", "true") \
    .option("inferSchema", "true") \
    .csv(norm_path)

end_norm = time.time()



# print("Duration of reading a GZIP file 1.1 GB (8 GB): ", end_gzip - start_gzip)
print("Duration of reading normal file 8 GB: ", end_norm - start_norm)
