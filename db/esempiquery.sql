# La tabella delle aperture dei negozi nelle settimane comuni (quelle senza festività al
# loro interno), ovvero tutti i negozi e i loro orari nei vari giorni, Ordinando la ricerca
# per zone e coi giorni della settimana disposti in ordine.

SELECT Destinazione.Nome, Indirizzo, Comune, GiornoS, HAperto, HCHiuso
FROM Destinazione INNER JOIN Apertura ON Destinazione.Id=IdL INNER JOIN Riferita ON Apertura.Id=IdA INNER JOIN Giorno ON GiornoS=Giorno.Nome
WHERE Festivo=FALSE OR Giorno.Nome="Domenica" OR Giorno.Nome="Sabato"
ORDER BY Comune, Indirizzo, Destinazione.Nome, FIELD(GiornoS, 'Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato', 'Domenica'),HAperto, HChiuso;

# L’elenco dei distributori e dei carburanti che gli utenti hanno indicato disponibili in
# ognuno di essi, indicando il prezzo minore mai segnalato per ogni tipo di carburante
# in quel distributore.

SELECT DISTINCT Nome, Indirizzo, Comune, TipoC, MIN(Prezzo) AS MinorPrezzo
FROM Distributore INNER JOIN Rilevamento ON Id=IdD
GROUP BY Nome,TipoC
ORDER BY Comune, Indirizzo, Nome ,TipoC;

# L’elenco dei luoghi che non fanno orario continuato, indicando i giorni nei quali
# questo accade. (Non vengono considerate le aperture NULL poiché indicano la
# continuazione dell’apertura del giorno precedente).

SELECT Nome, Indirizzo, Comune, GiornoS
FROM Destinazione INNER JOIN Apertura ON Destinazione.Id=IdL
INNER JOIN Riferita ON Apertura.Id=IdA
WHERE HAperto IS NOT NULL
GROUP BY Destinazione.Id, GiornoS
HAVING COUNT(GiornoS)>1;

# L’elenco dei luoghi che possiedono sia parcheggi coperti che scoperti.

SELECT Destinazione.Nome, Destinazione.Indirizzo, Destinazione.Comune
FROM Proprieta INNER JOIN Parcheggio ON IdP=Parcheggio.Id
INNER JOIN Destinazione ON IdL=Destinazione.Id
WHERE Coperto=TRUE AND IdL IN (
    SELECT IdL
    FROM Proprieta INNER JOIN Parcheggio ON IdP=Id
    WHERE Coperto=FALSE);

# La distanza di tutti i parcheggi dalla Basilica di Sant'Antonio (coordinate 45.401387,
# 11.880775), entro un raggio di 2km ordinati per distanza, indicando il prezzo per
# un’autovettura che parcheggia alla domenica alle 8:00.

SELECT Destinazione.Nome AS Destinazione , Parcheggio.Nome As Parcheggio, Distanza(Destinazione.Latitudine, Destinazione.Longitudine, Parcheggio.Latitudine, Parcheggio.Longitudine) AS Distanza, PrezzoH, GiornoS, ClasseV
FROM Destinazione, Parcheggio INNER JOIN Orario ON Parcheggio.Id=Orario.IdP INNER JOIN Applicato ON Orario.Id=Applicato.IdO INNER JOIN Disponibilita ON Orario.Id=Disponibilita.IdO
WHERE Destinazione.Nome LIKE "Basilica S Antonio" AND Destinazione.Latitudine=45.401387 AND Destinazione.Longitudine=11.880775 AND GiornoS="Domenica" AND HInizio<080000 AND HFine>080000 AND ClasseV="Autovettura"
HAVING Distanza<2
ORDER BY Distanza ASC;

# I parcheggi che sono in grado di ospitare un veicolo del quale non si conosce la
# classe con le seguenti caratteristiche: 3,6 tonnellate, 5 metri di lunghezza, 2.5 di
# larghezza, 3.5 di altezza, 110 watt di potenza e 2000 mq di cilindrata

SELECT Parcheggio.Nome, ClasseV As MioVeicolo
FROM Parcheggio INNER JOIN Orario ON Parcheggio.Id=Orario.IdP INNER JOIN Disponibilita D ON Orario.Id=D.IdO 
WHERE ClasseV= TrovaClasse(3.6,5,2.5,3.5,110,2000);
