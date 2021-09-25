md"""
## Exercise 1 - **n Volcanic bomb**
"""

#md # 👉 [Download the notebook to get started with this exercise!](https://github.com/eth-vaw-glaciology/course-101-0250-00/blob/main/notebooks/lecture2_ex1.ipynb)
#md #

md"""
The goal of this exercise is to consolidate:
- vectorisation and element-wise operations using `.`
- random numbers
- array initialisation
- conditional statement
"""

md"""
The goal is to extend the volcanic bomb calculator (exercise 4, lecture 1) to handle `nb` bombs.

To do so, start from the script you wrote to predict the trajectory of a single volcanic bomb and extend it to handle `nb` bombs.

Declare a new variable for the number of volcanic bombs
"""
nb = 5 # number of volcanic bombs

md"""
Then, replace the vertical angle of ejection α to randomly vary between 60° and 120° with respect to the horizon for each bomb. Keep the magnitude of the ejection velocity as before, i.e. $V=120$ m/s.
"""

#nb # > 💡 hint:
#nb # > - use the `randn()` function to generate random numbers in the range [-1, 1]
#md # \note{- use the `randn()` function to generate random numbers in the range [-1, 1]}

md"""
All bombs have the same initial location $(x=0, y=480)$ as before.

Implement the necessary modifications in the time loop in order to update the position of all volcanic bombs correctly.

Ensure the bombs stop their motion once they hit the ground (at position $y=0$).

### Question 1

Report the total time it takes for the last, out of 5, volcanic bombs to hit the ground and provide a figure that visualise the bombs' overall trajectories.

### Question 2

Repeat the exercise 1 but vectorise all your code, i.e. make use of broadcasting capabilities in Julia (using `.` operator) to only have a single loop for advancing in time.

"""
