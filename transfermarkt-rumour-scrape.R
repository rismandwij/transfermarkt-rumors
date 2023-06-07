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
rumor<-read_html(remDr$getPageSource(url)[[1]]) %>% html_nodes(".hauptlink")
rumor<-rumor %>% html_text2() %>% str_split("\n") %>% unlist()
print(rumor)
#Mengambil nama pemain yang sedang dirumorkan pindah
nama_pemain<-rumor[seq(1,length(rumor),by=4)]
print(nama_pemain)
#Mengambil nama klub asal dari pemain yang sedang dirumorkan
klub_asal<-rumor[seq(2,length(rumor),by=4)]
print(klub_asal)
#Mengambil nama klub tujuan dari pemain yang sedang dirumorkan
klub_rumor<-rumor[seq(3,length(rumor),by=4)]
print(klub_rumor)
#Mengambil persentase rumor kepindahan pemain 
persentase_rumor<-as.numeric(gsub("[^[:alnum:]]","",rumor[seq(4,length(rumor),by=4)]))
print(persentase_rumor)

rumor2<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes("table") %>% html_table()
rumor2<-as.data.frame(rumor2[[1]])
rumor2<-rumor2[,1]
rumor2<-rumor2 %>% str_split("\n") %>% unlist()
rumor2<-str_squish(rumor2)
rumor2<-rumor2[rumor2!=""]
#Mengambil posisi bermain dari pemain yang sedang dirumorkan 
posisi<-rumor2[seq(2,length(rumor2),by=2)]

rumor3<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes("table") %>% html_table()
rumor3<-as.data.frame(rumor3[[1]])
rumor4<-rumor3[,15]
rumor4<-rumor4[is.na(rumor4)==FALSE]
rumor5<-rumor3[,17]
rumor5<-rumor5[is.na(rumor5)==FALSE]
#Mengambil kontrak klub asal dari pemain yang sedang dirumorkan
kontrak_habis<-rumor4
#Mengambil waktu berita pemain yang sedang dirumorkan
tanggal_rumor<-rumor5

rumor6<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes(".zentriert") 
rumor6<-rumor6[-c(1:5)]
rumor6<-rumor6[seq(1,length(rumor6),4)] %>% html_text2()
#Mengambil umur pemain yang sedang dirumorkan
umur<-as.numeric(rumor6)

rumor7<-read_html(remDr$getPageSource()[[1]]) %>% html_nodes(".rechts") 
rumor7<-rumor7[-c(1,2)]
rumor7<-rumor7[seq(1,length(rumor7),2)] %>% html_text2()
#Mengambil harga pemain (dalam Euro) yang sedang dirumorkan
harga_pemain<-gsub("[A-Za-z]","",rumor7)
harga_pemain<-as.numeric(gsub("€","",harga_pemain))

data_pemain<-data.frame(tanggal_rumor,nama_pemain,umur,posisi,klub_asal,harga_pemain,kontrak_habis,klub_rumor,persentase_rumor)
data_pemain<-data_pemain[1:10,]

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
