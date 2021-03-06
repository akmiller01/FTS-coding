# install.packages("plyr")
# install.packages("readxl")
library(readxl)
library(plyr)

wd <- "C:/git/FTs-coding"
setwd(wd)

#Define renamed vars
csv_names <- c(
  "Flow ID"
  ,"Flow status"
  ,"Flow date"
  ,"Description"
  ,"Amount (USD)"
  ,"Original amount"
  ,"Original currency"
  ,"Exchange rate"
  ,"Flow type"
  ,"Contribution type"
  ,"Budget year"
  ,"Decision date"
  ,"Version ID"
  ,"Created"
  ,"Last updated"
  ,"Modality"
  ,"Donor project code"
  ,"Reporting organization"
  ,"Donor"
  ,"Source Organization type"
  ,"Source Emergency"
  ,"Source Location"
  ,"Source Project"
  ,"Source Usage year"
  ,"Source Plan"
  ,"Source Cluster"
  ,"Source Sector"
  ,"Recipient Organization"
  ,"Destination Organization type"
  ,"Destination Emergency"
  ,"Destination Country"
  ,"Destination Project"
  ,"Destination Usage year"
  ,"Destination Plan"
  ,"Destination Cluster"
  ,"Destination Sector"
)

#Format them as if R did it automatically
csv_names <- make.names(csv_names)

data <- read_excel("All 2016 flows.xls",sheet="Results - Incoming",skip=3,col_names=csv_names)

#Remove total row
#Note sure "Total: " still applies, I'll remove the comma and make it case insensitive to pick it up in case
data <- subset(data,!grepl("total",Donor,ignore.case=TRUE))

# Remove government of
data$Donor <- gsub(", Government of","",data$Donor)
unique(data$Donor)
data$Recipient.Organization <- gsub(", Government of","",data$Recipient.Organization)
unique(data$Recipient.Organization)

#Merge to create new column "Code name" based on donor type
codenames <- read.csv("codename.csv",na.strings="",as.is=TRUE)
codenames$lower.Donor <- tolower(codenames$Donor)
codenames <- codenames[!duplicated(codenames$lower.Donor),]
codenames$Donor <- NULL
data$lower.Donor <- tolower(data$Donor)
data <- join(data, codenames, by='lower.Donor', type='left', match='all')

withoutCodename <- subset(data,is.na(codename))
unique(withoutCodename$Donor)
#Essentially just the gov'ts without codenames. Is that okay? Do we want to keep them in?


#Merge to create new column "Private money" based on donor type
#I don't have these csvs, but I'll double check the new var names match up
privatemoney <- read.csv("privatemoney.csv",na.strings="",as.is=TRUE)
privatemoney$lower.Donor <- tolower(privatemoney$Donor)
privatemoney <- privatemoney[!duplicated(privatemoney$lower.Donor),]
privatemoney$Donor <- NULL
data$lower.Donor <- tolower(data$Donor)
data <- join(data, privatemoney, by='lower.Donor', type='left', match='all')

withoutPrivate <- subset(data,is.na(privatemoney))
unique(withoutPrivate$Donor)


#Merge to create new column "Donor DAC region" based on donor type
donordacregion <- read.csv("dacregions.csv",na.strings="",as.is=TRUE)
donordacregion$lower.Donor <- tolower(donordacregion$Donor)
donordacregion <- donordacregion[!duplicated(donordacregion$lower.Donor),]
donordacregion$Donor <- NULL
data$lower.Donor <- tolower(data$Donor) 
data <- join(data, donordacregion, by='lower.Donor', type='left', match='all')

withoutDACRegion <- subset(data,is.na(donordacregion))
unique(withoutDACRegion$Donor)


#Merge to create new column "Appealing agency code name" based on recipient type
recipientcodename <- read.csv("recipientcodename.csv",na.strings="",as.is=TRUE)
recipientcodename$lower.Recipient.Organization <- tolower(recipientcodename$Recipient.Organization)
recipientcodename <- recipientcodename[!duplicated(recipientcodename$lower.Recipient.Organization),]
recipientcodename$Recipient.Organization <- NULL 
data$lower.Recipient.Organization <- tolower(data$Recipient.Organization)
data <- join(data, recipientcodename, by='lower.Recipient.Organization', type='left', match='all')

withoutRecipientcode <- subset(data,is.na(recipientcodename))
unique(withoutRecipientcode$Recipient.Organization)


#Merge to create new column "Recip Org NGO type" based on recipient type
ngotype <- read.csv("ngotype.csv",na.strings="",as.is=TRUE)
ngotype$lower.Recipient.Organization <- tolower(ngotype$Recipient.Organization)
ngotype <- ngotype[!duplicated(ngotype$lower.Recipient.Organization),]
ngotype$Recipient.Organization <- NULL
data$lower.Recipient.Organization <- tolower(data$Recipient.Organization)
data <- join(data, ngotype, by='lower.Recipient.Organization', type='left', match='all')

withoutngos <- subset(data,is.na(ngotype))
unique(withoutngos$Recipient.Organization)

#Merge to create new column "Channels of delivery" based on recipient type
deliverychannels <- read.csv("deliverychannels.csv",na.strings="",as.is=TRUE)
deliverychannels$lower.Recipient.Organization <- tolower(deliverychannels$Recipient.Organization)
deliverychannels <- deliverychannels[!duplicated(deliverychannels$lower.Recipient.Organization),]
deliverychannels$Recipient.Organization <- NULL
data$lower.Recipient.Organization <- tolower(data$Recipient.Organization)
data <- join(data, deliverychannels, by='lower.Recipient.Organization', type='left', match='all')

withoutchannels <- subset(data,is.na(deliverychannels))
unique(withoutchannels$Recipient.Organization)

#Merge to create new column "Income group" based on destination country
incomegroups <- read.csv("incomegroups.csv",na.strings="",as.is=TRUE)
incomegroups$lower.Destination.Country <- tolower(incomegroups$Destination.Country)
incomegroups <- incomegroups[!duplicated(incomegroups$lower.Destination.Country),]
incomegroups$Destination.Country <- NULL 
data$lower.Destination.Country <- tolower(data$Destination.Country)
data <- join(data, incomegroups, by='lower.Destination.Country', type='left', match='all')

withoutincome <- subset(data,is.na(incomegroups))
unique(withoutincome$Destination.Country)

#Create new column "Domestic" 
data <- transform(data,domesticresponse=Donor==Destination.Country)


deflator <- read.csv("deflatorstrial2016.csv",na.strings="",as.is=TRUE)
deflator <- deflator[!duplicated(deflator$Donor),]

data <- join(data,deflator,by="Donor",type='left', match='all')
data <- transform(data,amountDeflated=Amount..USD./Deflatorvalue)
data <- transform(data,amountDeflatedMillions=amountDeflated/1000000)

withoutdeflators <- subset(data,is.na(Deflatorvalue))
unique(withoutdeflators$Donor)

#Remove Deflatorvalue column
data$Deflatorvalue <- NULL

#No longer have an X
# data$X <- NULL

write.csv(data,"fts_transformed.csv",na="",row.names=FALSE)

install.packages("data.table")
library(data.table)
donor.tab <- data.table(data)[,.(amountDeflatedMillions=sum(amountDeflatedMillions,na.rm=TRUE)),by=.(Donor,Flow.status)]
write.csv(donor.tab,"donor_flow_status.csv", na="",row.names=FALSE)

