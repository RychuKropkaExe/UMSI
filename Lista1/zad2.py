import csv
import numpy as np
import sys
from sklearn.linear_model import LinearRegression
from matplotlib import pyplot as plt
np.set_printoptions(threshold=sys.maxsize)
movies_data_iter = []
movies_data = []
with open('movies.csv','r') as f:
    movies_data_iter = csv.reader(f,
                           delimiter = ',',
                           quotechar = '"')
    movies_data = [data for data in movies_data_iter]

for i in range(1,len(movies_data)):
    movies_data[i][0] = int(movies_data[i][0])

movies_db = np.asarray(movies_data)

rating_data_iter = []
rating_data = []
with open('ratings.csv','r') as f:
    rating_iter = csv.reader(f,
                           delimiter = ',',
                           quotechar = '"')
    rating_data = [rating for rating in rating_iter]

for i in range(1,len(rating_data)):
    rating_data[i][0] = int(rating_data[i][0])

rating_db = np.asarray(rating_data)
users_array = []

for i in range(1,len(rating_db)):
    if rating_db[i][1] == '1':
        users_array.append(rating_db[i][0])
#print(users_array)

m = 10000

users_ratings_matrix = np.zeros((len(users_array), m))
toy_story_ratings_matrix = np.zeros(len(users_array))

for i in range(0, len(users_array)):
    for j in range(1,len(rating_db)):
        if rating_db[j][0] == users_array[i] and int(rating_db[j][1]) <= m and int(rating_db[j][1]) > 1 :
            users_ratings_matrix[i][int(rating_db[j][1])-2] = rating_db[j][2]
        if rating_db[j][0] == users_array[i] and int(rating_db[j][1]) == 1 :
            toy_story_ratings_matrix[i] = rating_db[j][2]

# print(users_ratings_matrix)
# print(toy_story_ratings_matrix)
            
training_ratings_matrix = users_ratings_matrix[:200,:]
training_toy_story_ratings = toy_story_ratings_matrix[:200]

test_X = users_ratings_matrix[200:215,:]
test_Y = toy_story_ratings_matrix[200:215]

plot_limit_m = 10000

scores_normal = []
for i in range(10,plot_limit_m,100):
    training_ratings_matrix = users_ratings_matrix[:200,:i]
    training_toy_story_ratings = toy_story_ratings_matrix[:200]
    test_ratings_matrix = users_ratings_matrix[:,:i]
    test_toy_story_ratings = toy_story_ratings_matrix[:]
    clf = LinearRegression().fit(training_ratings_matrix, training_toy_story_ratings)
    scores_normal.append(clf.score(test_ratings_matrix, test_toy_story_ratings))

steps = [step for step in range(10,plot_limit_m,100)]

#print(steps)

print(scores_normal)
# plot
fig, ax = plt.subplots()

ax.plot(steps, scores_normal, linewidth=1.0)

plt.savefig('plot_200_step_100.png', dpi=1200)
print(scores_normal)

