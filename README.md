# web-analytics-der-open-government-data-des-kantons-zuerich

In diesem Repository dokumentieren wir, wie der Kanton Zürich ausgewählte Web Analytics zu seinen offenen Behördendaten (OGD) erstellt, die er auf dem zentralen Metadaten-Katalog opendata.swiss publiziert.

Wir erstellen monatliche Reports der *Zugriffe auf Datensätze* von Organen des Kantons Zürich in R und exportieren diese als .csv-Ressource. Diesen Report publizieren wir jeweils in der ersten Woche des Folgemonats unter https://opendata.swiss/de/dataset/web-analytics-der-open-government-data-des-kantons-zuerich

Um einen Report zu erstellen, sprechen wir zwei Schnittstellen (API) an und kombinieren diese Daten:
* die CKAN Action API des Metadaten-Katalogs opendata.swiss: https://handbook.opendata.swiss/support/api.html; dies ist eine offen zugängliche Schnittstelle.
* die API der Webanalye-Plattform (https://matomo.org) des Metadaten-Katalogs opendata.swiss; diese Schnittstelle ist nur für Organisationen zugänglich, die Metadaten auf bzw. via opendata.swiss publizieren.

Die *Funktionen* sind im File 'data_download.R' beschrieben: https://github.com/openZH/web-analytics-der-open-government-data-des-kantons-zuerich/blob/master/data_download.R

Ein *Beispiel einer Report-Erstellung* ist im File 'template.R' beschrieben: https://github.com/openZH/web-analytics-der-open-government-data-des-kantons-zuerich/blob/master/template.R
