from newspaper import Article
import nltk
nltk.download('punkt')
#A new article from TOI
url = "https://www.thelallantop.com/factcheck/fact-check-hindu-idols-were-not-destroyed-by-muslims-in-kakrola-dwarka-delhi-sudarshan-tv-and-suresh-chavhanke-spread-fake-news/"

#For different language newspaper refer above table
toi_article = Article(url, language="en") # en for English

#To download the article
toi_article.download()

#To parse the article
toi_article.parse()

#To perform natural language processing ie..nlp
toi_article.nlp()

#To extract title
print("Article's Title:")
print(toi_article.title)
print("n")

#To extract text
print("Article's Text:")
print(toi_article.text)
print("n")

#To extract summary
print("Article's Summary:")
print(toi_article.summary)
print("n")

#To extract keywords
print("Article's Keywords:")
print(toi_article.keywords)

