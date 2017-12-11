# install.packages("simstudy")
# library("simstudy")

#https://cran.r-project.org/web/packages/simstudy/vignettes/simstudy.html

Days_off_def <- defData(varname = "nurse",
                        dist = "uniformInt",
                        formula = "1;25")
Days_off_def <- defData(Days_off_def,
                        varname = "Day_of_Month",
                        dist = "uniformInt",
                        formula = "1;30")

Days_off_requests <- genData(300, Days_off_def)

Expected_hourly_demand <- write.csv(Days_off_requests, file = "Days_off_requests.csv")
