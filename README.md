# Czech Public Television and Climate Change Reporting, 2012-2022

*Andrea Culkova (Academy of Performing Arts in Prague) <br>
Ondrej Pekacek (Charles University) <br>
Irena Reifova (Charles University) <br>
Irene Elmerot (Stockholm University)*

## A transformative journalism perspective

This is a research project examining the coverage of climate change by Czech public media outlets, ČT 1 and ČT 24.
The repository contains scripts, data and documentation for the computational part of the overall analysis.

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
