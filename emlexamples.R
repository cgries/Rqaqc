#get EML package out of github
install_github("EML", "ropensci")
#get the developer version
install_github("EML", "ropensci", "devel")
#get an EML file from knb, e.g. Syd's
eml <- read.eml("knb.434.4")
#show the EML
eml
#get sepcific parts from the EML
eml_get(eml, "creator")
#or drill down into the XML tree get to a help with tab
eml@dataset@title