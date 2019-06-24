# web-analytics-der-open-government-data-des-kantons-zuerich

In diesem Repository dokumentieren wir, wie der Kanton Zürich ausgewählte Web Analytics zu seinen offenen Behördendaten (OGD), die er auf dem zentralen Metadaten-Katalogs opendata.swiss publiziert, erstellt.

Wir erstellen monatliche Reports der Zugriffe auf Datensätze von Organen des Kantons Zürich in R und exportieren diese als .csv-Ressource. Diese publizieren wir in der ersten Woche des Folgemonats unter https://opendata.swiss/de/dataset/web-analytics-der-open-government-data-des-kantons-zuerich

Um die monatlichen Reports zu erstellen, sprechen wir zwei Schnittstellen (API) an und kombinieren diese Daten:
* CKAN Action API des Metadaten-Katalogs opendata.swiss: https://handbook.opendata.swiss/support/api.html; dies ist eine offen zugängliche Schnittstelle.
* API der https://matomo.org/ Instanz des Metadaten-Katalogs opendata.swiss; diese Schnittstelle ist nur für Organisationen zugänglich, die Metadaten auf bzw. via opendata.swiss publizieren.

Die Beschreibung der einzelnen Daten befinden sich im File.

Ein Beispiel eines Daten-Downloads ist ganz oben im File vorhanden.
