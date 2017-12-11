using JuMP
using Gurobi
using DataArrays
using DataFrames
using Gadfly

Requests = readcsv("Days_off_requests.csv")
Requests = Requests[:, 3:4]
Requests = DataFrame(nurse=Requests[2:size(Requests, 1),1],
                    Day_of_month=Requests[2:size(Requests, 1),2])

Num_nurse = maximum(Requests[:nurse])
Num_days = 30

Requests_matrix = zeros(Num_nurse, Num_days)
for i=1:size(Requests, 1)
    Requests_matrix[Requests[i,1], Requests[i,2]] = 1
end
Requests_matrix

e_hourly_demand = DataFrame(
    hour     = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
        12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23],
    E_demand = [4, 3, 3, 2, 2, 4, 5, 5, 6, 7,  7,  6,
         5,  5,  6,  6,  7,  7,  7,  6,  6,  5,  5,  5]
)

shifts = DataFrame(
    shift_start = [0, 4, 8, 12, 16, 20],
    nurses_reqd = [3, 2, 5,  2,  5,  0]
)

m = Model(solver = GurobiSolver())

#i = nurse ID, j = day, k = shift
@variable(m, X[1:Num_nurse,1:Num_days,1:size(shifts, 1)], Bin)

@objective(m, Min, sum(X[i,j,k]*Requests_matrix[i,j]
    for k=1:size(shifts,1), j=1:Num_days, i=1:Num_nurse))

#all shifts get covered
@constraint(m, coverage[j=1:Num_days, k=1:size(shifts, 1)],
    sum(X[i,j,k] for i=1:Num_nurse) == shifts[k,2])

#everyone gets the hours they need
@constraint(m, Max_work[i=1:Num_nurse],
    sum(X[i,j,k]*10 for j=1:Num_days, k=1:size(shifts,1))<=60*4)
@constraint(m, Min_work[i=1:Num_nurse],
    sum(X[i,j,k]*10 for j=1:Num_days, k=1:size(shifts,1))>=30*4)

# cannot have 2 shifts within 24 hrs of the first shift's start
@constraint(m, Shifts_within[i=1:Num_nurse, j=1:Num_days],
    sum(X[i,j,k] for k=1:size(shifts,1)) <= 1)
@constraint(m, Shifts_within_x[i=1:Num_nurse, j=2:Num_days],
    sum(X[i,j-1,k] for k=1:3)+sum(X[i,j-1,k] for k=4:6) <= 1)

status = solve(m)
Assignment = getvalue(X)
