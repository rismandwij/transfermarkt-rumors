#Loading Packages
message("Loading Packages")
library(RSelenium)
library(wdman)
library(netstat)
library(rvest)
library(tidyverse)
library(mongolite)
library(binman)

#Connect RSelenium
message("Loading Selenium")
selenium()
x<-list_versions("chromedriver")
file.remove(paste0("C:/Users/RUNNER~1/AppData/Local/binman/binman_chromedriver/win32/",x$win32[1],"/LICENSE.chromedriver"))
remote_drver<-rsDriver(browser="chrome",chromever=x$win32[1],verbose=F,port = free_port())
remDr<-remote_drver$client

#Scraping
message("Start Scraping")
url<-"https://www.transfermarkt.com/premier-league/geruechte/wettbewerb/GB1/saison_id/2022/plus/1"
remDr$navigate(url)
jumlah_data<-10 #jumlah data yang akan diambil
data_pemain<-data.frame(id=1:jumlah_data)
rumor<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes(".hauptlink")
rumor<-rumor %>% html_text2() %>% str_split("\n") %>% unlist()
rumor<-matrix(rumor,ncol=4,byrow=T)
rumor<-rumor[1:jumlah_data,]
#Mengambil nama pemain yang sedang dirumorkan
data_pemain$nama_pemain<-rumor[,1]
#Mengambil nama klub asal dari pemain yang sedang dirumorkan
data_pemain$klub_asal<-rumor[,2]   
#Mengambil nama klub tujuan dari pemain yang sedang dirumorkan
data_pemain$klub_rumor<-rumor[,3]
#Mengambil persentase rumor kepindahan pemain 
data_pemain$persentase_rumor<-as.numeric(gsub("[^[:alnum:]]","",rumor[,4]))

rumor2<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes("table") %>% html_table()
rumor2<-as.data.frame(rumor2[[1]])
rumor2<-rumor2[,1]
rumor2<-rumor2 %>% str_split("\n") %>% unlist()
rumor2<-matrix(rumor2,ncol=2,byrow=T)
rumor2<-str_squish(rumor2[,2])
rumor2<-rumor2[rumor2!=""]
#Mengambil posisi bermain dari pemain yang sedang dirumorkan 
data_pemain$posisi<-rumor2[1:jumlah_data]

rumor3<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes("table") %>% html_table()
rumor3<-as.data.frame(rumor3[[1]])
rumor4<-rumor3[,15]
rumor4<-rumor4[is.na(rumor4)==FALSE]
rumor5<-rumor3[,17]
rumor5<-rumor5[is.na(rumor5)==FALSE]
#Mengambil kontrak klub asal dari pemain yang sedang dirumorkan
data_pemain$kontrak<-rumor4[1:jumlah_data]
#Mengambil waktu berita pemain yang sedang dirumorkan
data_pemain$tanggal_rumor<-rumor5[1:jumlah_data]

rumor6<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes(".zentriert") 
rumor6<-rumor6[-c(1:5)]
rumor6<-rumor6[seq(1,length(rumor6),4)] %>% html_text2()
#Mengambil umur pemain yang sedang dirumorkan
data_pemain$umur<-as.numeric(rumor6[1:jumlah_data])

rumor7<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes(".rechts") 
rumor7<-rumor7[-c(1:2)]
rumor7<-rumor7[seq(1,length(rumor7),2)] %>% html_text2()
data_pemain$harga_pemain<-gsub("[A-Za-z]","",rumor7[1:jumlah_data])
#Mengambil harga pemain (dalam Euro) yang sedang dirumorkan 
data_pemain$harga_pemain<-as.numeric(gsub("€","",data_pemain$harga_pemain))
data_pemain<-data_pemain[,-1]

message("Connect to MongoDB Atlas")
#MONGODB
atlas_conn <- mongo(
  collection = Sys.getenv("ATLAS_COLLECTION"),
  db         = Sys.getenv("ATLAS_DB"),
  url        = Sys.getenv("ATLAS_URL")
)

message("Input to MongoDB Atlas Collection")
atlas_conn$insert(data_pemain)

rm(atlas_conn)
