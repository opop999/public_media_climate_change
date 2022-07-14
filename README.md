# Czech public television and climate change reporting, 2012-2022
## A transformative journalism perspective

This is a research project examining the coverage of climate change by Czech public media outlets, ČT 1 and ČT 24.
The repository contains scripts, data and documentation for the computational part of the overall analysis.

### Project workflow diagram

```mermaid
graph TD;
  style newton  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style raw_data  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style regex  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style udpipe  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style climate_corpus  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style clean_data  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style eda  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style udpipe  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style nlp  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style counts  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style length  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style lda  fill: #041e42, stroke: #ed1c24, stroke-width: 1px
  style ner  fill: #041e42, stroke: #ed1c24, stroke-width: 1px

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
