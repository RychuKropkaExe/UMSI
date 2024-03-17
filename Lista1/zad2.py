import csv
import numpy as np
import sys
from sklearn.linear_model import LinearRegression
from matplotlib import pyplot as plt
import random
np.set_printoptions(threshold=sys.maxsize)

rating_data_iter = []
rating_data = []
with open('ratings.csv','r') as f:
    rating_iter = csv.reader(f,
                           delimiter = ',',
                           quotechar = '"')
    rating_data = [rating for rating in rating_iter]

rating_db = np.asarray(rating_data)

m = 10000

max_movie_id = 0
max_user_id = 610
#max_user_id = 10

movies_counters = np.zeros(m)

for i in range(1,len(rating_db)):
    if int(rating_db[i][1]) <= m:
        movies_counters[int(rating_db[i][1])-1] += 1
    if int(rating_db[i][1]) > max_movie_id and int(rating_db[i][1]) <= m:
        max_movie_id = int(rating_db[i][1])

counter = 0
for i in range(m):
    if movies_counters[i] > 0:
        counter+=1

my_ratings = np.zeros((max_movie_id,1))

users_ratings_matrix = np.zeros((max_user_id, max_movie_id))
for i in range(1,len(rating_db)):
    if int(rating_db[i][1]) <= m and int(rating_db[i][0]) <= max_user_id:
        users_ratings_matrix[int(rating_db[i][0])-1][int(rating_db[i][1])-1] = rating_db[i][2]


for i in range(len(my_ratings)):
    if random.random() <= 0.33:
        my_ratings[i] = random.randint(3, 5)

my_ratings_norms = np.nan_to_num(np.linalg.norm(my_ratings))
my_ratings_normalized = np.nan_to_num(my_ratings/my_ratings_norms)

users_ratings_matrix_norms = np.nan_to_num(np.linalg.norm(users_ratings_matrix, axis=0))

users_ratings_matrix_normalized = np.nan_to_num(users_ratings_matrix/users_ratings_matrix_norms)

cosine_we_users=np.dot(users_ratings_matrix_normalized, my_ratings_normalized)

our_profile = np.nan_to_num(cosine_we_users/np.linalg.norm(cosine_we_users))

result = np.dot(users_ratings_matrix_normalized.T, our_profile)

result_with_movies_id = np.zeros((max_movie_id, 2))

for i in range(max_movie_id):
    result_with_movies_id[i][0] = result[i]
    result_with_movies_id[i][1] = i

result_with_movies_id = result_with_movies_id.tolist()

def myKeyComp(e):
    return e[0]

sorted_results = sorted(result_with_movies_id, key=myKeyComp, reverse=True)

movies_data_iter = []
movies_data = []
with open('movies.csv','r') as f:
    movies_data_iter = csv.reader(f,
                           delimiter = ',',
                           quotechar = '"')
    movies_data = [data for data in movies_data_iter]

for i in range(1,len(movies_data)):
    movies_data[i][0] = int(movies_data[i][0])

movies_names_db = [None]*max_movie_id
for i in range(1,len(movies_data)):
    if int(movies_data[i][0]) <= max_movie_id: 
        movies_names_db[int(movies_data[i][0])-1] = movies_data[i][1]

for i in range(10):
    print("RECOMENDED MOVIE: ", movies_names_db[int(sorted_results[i][1])], " WITH VALUE: ", sorted_results[i][0])

