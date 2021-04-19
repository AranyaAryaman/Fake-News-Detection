import youtube_dl 
y= {}  
while (1):  
    link= input("Copy & paste the URL of the YouTube video you want to download:- ")  
    youtube_dl.YoutubeDL(y).download([link]) 
    f=input("\nENETR YES(Y) TO CONTINUE DOWNLOADING VIDEOS \nELSE NO(N) TO STOP\n")  
    if f=="N" or f=="n": 
        break 

