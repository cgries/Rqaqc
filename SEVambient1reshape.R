#install and use the library 'reshape'
library(reshape)
#install and use RMySQL
#which is a nightmare and I ended up downloadign a pre-compiled zip file, which happens to work with my particular setup
library(RMySQL)
#install and use the library 'RODBC'
library(RODBC)


#these need to be changed for each format of .dat file

dataheader <- "\"TIMESTAMP\",\"RECORD\",\"batt_Avg\",\"aTemp_Avg\",\"bPressure_Avg\""
tableheader <- c("TIMESTAMP","RECORD","batt_Avg","aTemp_Avg","bPressure_Avg")
getpath <- "C:/Users/cgries/Documents/downloads/warming_sev/warming"
putpath <- "C:/Users/cgries/Documents/downloads/warming_sev/warming"
filenamebasic <- "ambient1"

#this may need changing
years <- c(2005:2014)
emptycell <- c("NaN", "-9999", "NAN")

#don't change this
runcount <- 0


#read the folder names within the given folder
directories <- dir(path = getpath, pattern="20*", full.names=TRUE)

#loop through the folders to read each file
for (i in seq(along=directories)){
  filenames <- dir(path = directories[i], full.names=TRUE)
  #print(directories[i])
  for (j in seq(along=filenames)){
    
    #open a connection to the file to read the header line - line 2 in campbell files
    con <- file(filenames[j],open="r")
    line <- readLines(con, n=2)
    header <- "something"
    #make sure the file has enough lines
    if(length(line) == 2){
      header <- line[2]
    }
    close(con)
    #figure out which type of file it is based on the header line
    if (header == dataheader){
      temptable <- read.table(filenames[j], skip=4, sep=",", header = FALSE, col.names=tableheader, na.strings = emptycell, as.is=TRUE)
      if(runcount == 0){
        finaltable <- temptable
      }
      if(runcount > 0){
        finaltable <- rbind(finaltable,temptable)
      }
      runcount <- runcount + 1
    }
  }  
}
#edit(finaltable)
attach(finaltable)
sortedtable <- finaltable[order(TIMESTAMP),]

longtable <- melt(sortedtable, id=c("TIMESTAMP","RECORD"))

#adding a column indicating the quality control level
longtable$QClevel <- 1

#adding flags
longtable$flag <- ""
#battery level below 12.5 volt
L = longtable$variable == "batt_Avg" & longtable$value < 12.5
longtable[L,]$flag <- "B"

#temperature outside range
T = longtable$variable == "aTemp_Avg" & (longtable$value < 0 | longtable$value > 30)
longtable[T,]$flag <- "E"
#edit(longtable)

putpathnew <- paste(putpath,"/",filenamebasic,".csv",sep="")
write.csv(longtable, file=putpathnew)

detach(finaltable)

#with RMySQL, this is lightning fast
#save table to database, change table name
drv <- dbDriver("MySQL")
con <- dbConnect("MySQL", host="localhost", dbname="rtest", username="root", password="kimcor")
#this it doesn't seem to deal with dates correctly they are saved as text
dbWriteTable(con,"sev_ambient1",longtable)
dbDisconnect(con)

#with RODBC, this takes forever, i.e. hours!!!
#connection etc. with package RODBC
#with connection string:
#con<-odbcDriverConnect(connection="SERVER=localhost;DRIVER=MySQL ODBC 5.1 Driver;DATABASE=rtest;UID=root;PWD=kimcor")
#with a named ODBC datasource established in control panel/administrative tasks/ODBC connections
con <- odbcConnect("localhostRtest")
sqlSave(con, longtable, tablename="sev_ambient11")
odbcClose(con)
