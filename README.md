# Czech Public Television and Climate Change Reporting, 2012-2022

*Andrea Culkova (Academy of Performing Arts in Prague) <br>
Ondrej Pekacek (Charles University) <br>
Irena Reifova (Charles University) <br>
Irene Elmerot (Stockholm University)*

**Project website can be found [HERE](https://climate-topics.netlify.app/)**

## A transformative journalism perspective
This project aims to investigate how Czech public television (ČT 1 and ČT 24) covers climate change. As part of this project, we developed a computational research pipeline to analyze over 0.6 million transcripts from Czech Television between 2012 and 2022. The primary analysis for this project involved topic modeling using LDA and NMF algorithms to provide the best model determined by domain experts using lemmatized data with UDPIPE model. In addition to the primary analysis method, we also performed sentiment analysis using a pre-trained CZERT/BERT model, accelerated with GPU using Kaggle. We also developed a pipeline for keyword extraction using TF-IDF and KeyBERT from the lemmatized corpus and named entity recognition using a NameTag 2 model, which can distinguish about 50 entity categories in Czech.

As part of the public outreach, we have made the project open source.
This GitHub repository contains all the scripts used for our analysis (except for proprietary media data).
The project website also contains links to the visualizations of the individual topic models created.

### Project workflow diagram

```mermaid
graph TD;
    style newton fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style raw_data fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style regex fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style udpipe fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style climate_corpus fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style clean_data fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style eda fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style udpipe fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style nlp fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style counts fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style length fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style lda fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px
    style ner fill:#041e42,color:#fff,stroke:#ed1c24,stroke-width:1.5px

    newton[Newton Media API: <br> media articles, 2012-2022] ==> raw_data[(Raw media data)]
    raw_data ==> regex([Regex preprocessing])
    regex ==> udpipe([UDPIPE preprocessing])
    udpipe ---> clean_data[(Processed media data)]
    udpipe --> climate_corpus([Climate sub-corpus creation])
    climate_corpus --> clean_data
    clean_data ---> eda([Exploratory Data Analysis])
    clean_data ---> nlp([Natural Language Processing])
    eda --> counts[Counts over time]
    eda --> length[Average content lenght]
    nlp --> ner[Named Entity Recognition]
    nlp --> lda[LDA topic modeling]
```
